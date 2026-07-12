package points

import (
	"encoding/json"
	"log"
	"os"
	"sort"
	"strconv"
	"sync"
	"time"
)

type UserPoints struct {
	Username string `json:"username"`
	Points   int    `json:"points"`
}

type LedgerEntry struct {
	UserID    string `json:"user_id"`
	Event     string `json:"event"`
	Points    int    `json:"points"`
	Timestamp int64  `json:"timestamp"`
}

var (
	pointsLock sync.RWMutex
	balances   map[string]int
	ledger     []LedgerEntry
	pointsFile = "./data/points.json"
	ledgerFile = "./data/ledger.json"
)

func init() {
	balances = make(map[string]int)
	loadPoints()
}

func loadPoints() {
	pointsLock.Lock()
	defer pointsLock.Unlock()

	// Load balances
	data, err := os.ReadFile(pointsFile)
	if err != nil {
		if os.IsNotExist(err) {
			os.MkdirAll("./data", 0755)
			seedBalanceStr := os.Getenv("SEED_BALANCE")
			seedBalance := 0
			if seedBalanceStr != "" {
				if val, err := strconv.Atoi(seedBalanceStr); err == nil {
					seedBalance = val
				}
			}
			balances["panospds"] = seedBalance
			savePoints()
		} else {
			log.Printf("Error reading points.json: %v", err)
		}
	} else {
		if err := json.Unmarshal(data, &balances); err != nil {
			log.Printf("Error parsing points.json: %v", err)
		}
	}

	// Load ledger
	ledgerData, err := os.ReadFile(ledgerFile)
	if err == nil {
		if err := json.Unmarshal(ledgerData, &ledger); err != nil {
			log.Printf("Error parsing ledger.json: %v", err)
		}
	} else {
		ledger = []LedgerEntry{
			{UserID: "panospds", Event: "LifeOS Initial Seed Balance", Points: balances["panospds"], Timestamp: time.Now().Unix()},
		}
		saveLedger()
	}
}

func savePoints() {
	data, err := json.MarshalIndent(balances, "", "  ")
	if err != nil {
		log.Printf("Error marshaling points: %v", err)
		return
	}

	if err := os.WriteFile(pointsFile, data, 0644); err != nil {
		log.Printf("Error writing points.json: %v", err)
	}
}

func saveLedger() {
	data, err := json.MarshalIndent(ledger, "", "  ")
	if err != nil {
		log.Printf("Error marshaling ledger: %v", err)
		return
	}

	if err := os.WriteFile(ledgerFile, data, 0644); err != nil {
		log.Printf("Error writing ledger.json: %v", err)
	}
}

func GetBalance(username string) int {
	pointsLock.RLock()
	defer pointsLock.RUnlock()
	return balances[username]
}

func AddPoints(username string, amount int) int {
	return AddPointsWithEvent(username, amount, "Points modification")
}

func AddPointsWithEvent(username string, amount int, event string) int {
	pointsLock.Lock()
	defer pointsLock.Unlock()
	balances[username] += amount
	newBalance := balances[username]
	savePoints()

	// Append to ledger
	ledger = append([]LedgerEntry{{UserID: username, Event: event, Points: amount, Timestamp: time.Now().Unix()}}, ledger...)
	// Limit to last 50 entries
	if len(ledger) > 50 {
		ledger = ledger[:50]
	}
	saveLedger()

	return newBalance
}

func GetLedger() []LedgerEntry {
	pointsLock.RLock()
	defer pointsLock.RUnlock()
	if ledger == nil {
		return []LedgerEntry{}
	}
	return ledger
}

func GetLeaderboard() []map[string]interface{} {
	pointsLock.RLock()
	defer pointsLock.RUnlock()

	var users []UserPoints
	for u, p := range balances {
		users = append(users, UserPoints{Username: u, Points: p})
	}

	sort.Slice(users, func(i, j int) bool {
		return users[i].Points > users[j].Points
	})

	var leaderboard []map[string]interface{}
	for i, u := range users {
		leaderboard = append(leaderboard, map[string]interface{}{
			"username": u.Username,
			"points":   u.Points,
			"rank":     i + 1,
		})
	}
	return leaderboard
}
