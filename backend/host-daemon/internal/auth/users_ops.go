package auth

import (
	"golang.org/x/crypto/bcrypt"
	"os"
	"time"
)

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
