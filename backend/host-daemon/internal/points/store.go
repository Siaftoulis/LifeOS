package points

import (
	"encoding/json"
	"io/ioutil"
	"log"
	"os"
	"sort"
	"sync"
)

type UserPoints struct {
	Username string `json:"username"`
	Points   int    `json:"points"`
}

var (
	pointsLock sync.RWMutex
	balances   map[string]int
	pointsFile = "./data/points.json"
)

func init() {
	balances = make(map[string]int)
	loadPoints()
}

func loadPoints() {
	pointsLock.Lock()
	defer pointsLock.Unlock()

	data, err := os.ReadFile(pointsFile)
	if err != nil {
		if os.IsNotExist(err) {
			os.MkdirAll("./data", 0755)
			balances["panospds"] = 1540
			savePoints()
			return
		}
		log.Printf("Error reading points.json: %v", err)
		return
	}

	if err := json.Unmarshal(data, &balances); err != nil {
		log.Printf("Error parsing points.json: %v", err)
	}
}

func savePoints() {
	data, err := json.MarshalIndent(balances, "", "  ")
	if err != nil {
		log.Printf("Error marshaling points: %v", err)
		return
	}

	if err := ioutil.WriteFile(pointsFile, data, 0644); err != nil {
		log.Printf("Error writing points.json: %v", err)
	}
}

func GetBalance(username string) int {
	pointsLock.RLock()
	defer pointsLock.RUnlock()
	return balances[username]
}

func AddPoints(username string, amount int) int {
	pointsLock.Lock()
	defer pointsLock.Unlock()
	balances[username] += amount
	newBalance := balances[username]
	savePoints()
	return newBalance
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
