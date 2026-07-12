package player

import (
	"encoding/json"
	"log"
	"strings"
	"time"
)

type PlayerState struct {
	XP           int            `json:"xp"`
	Age          float64        `json:"age"`
	Willpower    float64        `json:"willpower"`
	Attributes   map[string]int `json:"attributes"`
	LastActiveAt int64          `json:"last_active_at"`
}

func GetPlayerState() PlayerState {
	var state PlayerState
	var attrs string
	
	err := DB.QueryRow("SELECT xp, age, willpower, attributes, last_active_at FROM player WHERE id = 'player-1'").Scan(
		&state.XP, &state.Age, &state.Willpower, &attrs, &state.LastActiveAt)
	if err != nil {
		log.Printf("Error fetching player state: %v", err)
		return state
	}
	
	json.Unmarshal([]byte(attrs), &state.Attributes)
	if state.Attributes == nil {
		state.Attributes = make(map[string]int)
	}
	return state
}

func UpdatePlayerXP(amount int) {
	state := GetPlayerState()
	state.XP += amount
	
	_, err := DB.Exec("UPDATE player SET xp = ? WHERE id = 'player-1'", state.XP)
	if err != nil {
		log.Printf("Error updating player XP: %v", err)
	}
}

func UpdateAttributeXP(attribute string, amount int) {
	if attribute == "" {
		return
	}
	attribute = strings.ToLower(attribute)
	
	state := GetPlayerState()
	if state.Attributes == nil {
		state.Attributes = make(map[string]int)
	}
	state.Attributes[attribute] += amount
	
	attrs, _ := json.Marshal(state.Attributes)
	_, err := DB.Exec("UPDATE player SET attributes = ? WHERE id = 'player-1'", string(attrs))
	if err != nil {
		log.Printf("Error updating player attribute XP: %v", err)
	}
}

func ApplyDecay() {
	state := GetPlayerState()
	now := time.Now().Unix()
	if state.LastActiveAt == 0 {
		DB.Exec("UPDATE player SET last_active_at = ? WHERE id = 'player-1'", now)
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

	attrs, _ := json.Marshal(state.Attributes)
	DB.Exec("UPDATE player SET xp = ?, attributes = ?, last_active_at = ? WHERE id = 'player-1'", state.XP, string(attrs), now)
}
