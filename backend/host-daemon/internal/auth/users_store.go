package auth

import (
	"encoding/json"
	"log"
	"os"
	"sync"
	"time"

	"golang.org/x/crypto/bcrypt"
)

var (
	usersLock sync.RWMutex
	usersMap  map[string]User
	usersFile = "./data/users.json"
)

func init() {
	usersMap = make(map[string]User)
	loadUsers()
}

func loadUsers() {
	usersLock.Lock()
	defer usersLock.Unlock()

	data, err := os.ReadFile(usersFile)
	if err != nil {
		if os.IsNotExist(err) {
			os.MkdirAll("./data", 0755)
			seedAdmin()
			return
		}
		log.Printf("Error reading users.json: %v", err)
		return
	}

	var usersList []User
	if err := json.Unmarshal(data, &usersList); err != nil {
		log.Printf("Error parsing users.json: %v", err)
		return
	}

	for _, u := range usersList {
		usersMap[u.Username] = u
	}

	if len(usersMap) == 0 {
		seedAdmin()
	}
}

func saveUsers() {
	var usersList []User
	for _, u := range usersMap {
		usersList = append(usersList, u)
	}

	data, err := json.MarshalIndent(usersList, "", "  ")
	if err != nil {
		log.Printf("Error marshaling users: %v", err)
		return
	}

	if err := os.WriteFile(usersFile, data, 0644); err != nil {
		log.Printf("Error writing users.json: %v", err)
	}
}

func seedAdmin() {
	hash, err := bcrypt.GenerateFromPassword([]byte("1897"), bcrypt.DefaultCost)
	if err != nil {
		log.Printf("Error generating admin seed password hash: %v", err)
		return
	}
	admin := User{
		ID:           "u-admin-1",
		Username:     "panospds",
		PasswordHash: string(hash),
		Role:         "ADMIN",
		AvatarAsset:  "",
		DisplayName:  "Panos PDS",
		Status:       "System Administrator",
		CreatedAt:    time.Now().Unix(),
	}
	usersMap[admin.Username] = admin
	saveUsers()
}
