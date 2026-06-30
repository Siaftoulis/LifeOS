package player

import (
	"encoding/json"
	"log"
	"os"
	"sync"
	"time"
)

type PlayerState struct {
	XP           int            `json:"xp"`
	Age          float64        `json:"age"`
	Willpower    float64        `json:"willpower"`
	Attributes   map[string]int `json:"attributes"`
	LastActiveAt int64          `json:"last_active_at"`
}

var (
	playerLock sync.RWMutex
	state      PlayerState
	playerFile = "./data/player.json"
)

func init() {
	state = PlayerState{
		XP:         15400,
		Age:        30.0,
		Willpower:  110.0,
		Attributes: map[string]int{
			"stamina":      100,
			"intelligence": 150,
			"focus":        120,
			"charisma":     90,
			"willpower":    110,
		},
	}
	loadPlayerState()
}

func loadPlayerState() {
	playerLock.Lock()
	defer playerLock.Unlock()

	data, err := os.ReadFile(playerFile)
	if err != nil {
		if os.IsNotExist(err) {
			os.MkdirAll("./data", 0755)
			savePlayerState()
			return
		}
		log.Printf("Error reading player.json: %v", err)
		return
	}

	if err := json.Unmarshal(data, &state); err != nil {
		log.Printf("Error parsing player.json: %v", err)
	}
	
	if state.Attributes == nil {
	    state.Attributes = make(map[string]int)
	}
}

func savePlayerState() {
	data, err := json.MarshalIndent(state, "", "  ")
	if err != nil {
		log.Printf("Error marshaling player state: %v", err)
		return
	}

	if err := os.WriteFile(playerFile, data, 0644); err != nil {
		log.Printf("Error writing player.json: %v", err)
	}
}

func GetPlayerState() PlayerState {
	playerLock.RLock()
	defer playerLock.RUnlock()
	return state
}

func UpdatePlayerXP(amount int) {
	playerLock.Lock()
	defer playerLock.Unlock()
	state.XP += amount
	savePlayerState()
}

func UpdateAttributeXP(attribute string, amount int) {
	if attribute == "" {
		return
	}
	playerLock.Lock()
	defer playerLock.Unlock()
	if state.Attributes == nil {
		state.Attributes = make(map[string]int)
	}
	state.Attributes[attribute] += amount
	savePlayerState()
}

func ApplyDecay() {
	playerLock.Lock()
	defer playerLock.Unlock()

	now := time.Now().Unix()
	if state.LastActiveAt == 0 {
		state.LastActiveAt = now
		savePlayerState()
		return
	}

	daysInactive := int((now - state.LastActiveAt) / 86400)
	if daysInactive > 0 {
		decayRate := CalculateXPDecayRate(state.Willpower, daysInactive)
		if decayRate > 0 {
			lostXP := int(float64(state.XP) * decayRate)
			state.XP -= lostXP
			if state.XP < 0 {
				state.XP = 0
			}
			log.Printf("Applied XP Decay: Lost %d XP due to %d inactive days", lostXP, daysInactive)
		}

		atrophy := CalculateStatAtrophy(state.Willpower, daysInactive)
		if atrophy > 0 {
			for attr, val := range state.Attributes {
				state.Attributes[attr] = val - atrophy
				if state.Attributes[attr] < 0 {
					state.Attributes[attr] = 0
				}
			}
			log.Printf("Applied Attribute Atrophy: Lost %d points due to %d inactive days", atrophy, daysInactive)
		}
	}

	state.LastActiveAt = now
	savePlayerState()
}
