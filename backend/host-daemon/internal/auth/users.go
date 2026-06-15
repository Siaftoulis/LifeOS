package auth

import (
	"encoding/json"
	"io/ioutil"
	"log"
	"os"
	"sync"
	"time"

	"golang.org/x/crypto/bcrypt"
)

type User struct {
	ID           string `json:"id"`
	Username     string `json:"username"`
	PasswordHash string `json:"password_hash"`
	Role         string `json:"role"` // ADMIN or USER
	AvatarAsset  string `json:"avatar_asset"`
	DisplayName  string `json:"display_name"`
	Status       string `json:"status"`
	CreatedAt    int64  `json:"created_at"`
}

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

	data, err := ioutil.ReadFile(usersFile)
	if err != nil {
		if os.IsNotExist(err) {
			// Ensure data dir exists
			os.MkdirAll("./data", 0755)
			// Seed the admin user if file doesn't exist
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

	if err := ioutil.WriteFile(usersFile, data, 0644); err != nil {
		log.Printf("Error writing users.json: %v", err)
	}
}

func seedAdmin() {
	hash, _ := bcrypt.GenerateFromPassword([]byte("1897"), bcrypt.DefaultCost)
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

func AuthenticateUser(username, password string) (*User, bool) {
	usersLock.RLock()
	defer usersLock.RUnlock()

	user, exists := usersMap[username]
	if !exists {
		return nil, false
	}

	err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password))
	if err != nil {
		return nil, false
	}

	return &user, true
}

func CreateUser(username, password, role string) (*User, error) {
	usersLock.Lock()
	defer usersLock.Unlock()

	if _, exists := usersMap[username]; exists {
		return nil, os.ErrExist
	}

	hash, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	newUser := User{
		ID:           "u-" + time.Now().Format("20060102150405"),
		Username:     username,
		PasswordHash: string(hash),
		Role:         role,
		AvatarAsset:  "",
		DisplayName:  username,
		Status:       "Available",
		CreatedAt:    time.Now().Unix(),
	}

	usersMap[username] = newUser
	saveUsers()
	return &newUser, nil
}

func GetUsers() []User {
	usersLock.RLock()
	defer usersLock.RUnlock()

	var list []User
	for _, u := range usersMap {
		list = append(list, u)
	}
	return list
}

func UpdateProfile(username, displayName, status, avatar string) bool {
	usersLock.Lock()
	defer usersLock.Unlock()

	u, exists := usersMap[username]
	if !exists {
		return false
	}

	u.DisplayName = displayName
	u.Status = status
	u.AvatarAsset = avatar
	usersMap[username] = u

	saveUsers()
	return true
}
