package auth

import (
	"os"
	"time"

	"golang.org/x/crypto/bcrypt"
)

func AuthenticateUser(username, password string) (*User, bool) {
	dbLock.RLock()
	defer dbLock.RUnlock()

	var u User
	err := db.QueryRow(`
		SELECT id, username, password_hash, role, avatar_asset, display_name, status, created_at
		FROM users WHERE username = ?
	`, username).Scan(&u.ID, &u.Username, &u.PasswordHash, &u.Role, &u.AvatarAsset, &u.DisplayName, &u.Status, &u.CreatedAt)

	if err != nil {
		return nil, false
	}

	if err := bcrypt.CompareHashAndPassword([]byte(u.PasswordHash), []byte(password)); err != nil {
		return nil, false
	}

	return &u, true
}

func CreateUser(username, password, role string) (*User, error) {
	dbLock.Lock()
	defer dbLock.Unlock()

	var count int
	_ = db.QueryRow("SELECT COUNT(*) FROM users WHERE username = ?", username).Scan(&count)
	if count > 0 {
		return nil, os.ErrExist
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

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

	_, err = db.Exec(`
		INSERT INTO users (id, username, password_hash, role, avatar_asset, display_name, status, created_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)
	`, newUser.ID, newUser.Username, newUser.PasswordHash, newUser.Role, newUser.AvatarAsset, newUser.DisplayName, newUser.Status, newUser.CreatedAt)

	if err != nil {
		return nil, err
	}

	return &newUser, nil
}

func GetUsers() []User {
	dbLock.RLock()
	defer dbLock.RUnlock()

	rows, err := db.Query(`
		SELECT id, username, password_hash, role, avatar_asset, display_name, status, created_at
		FROM users
	`)
	if err != nil {
		return nil
	}
	defer rows.Close()

	var list []User
	for rows.Next() {
		var u User
		if err := rows.Scan(&u.ID, &u.Username, &u.PasswordHash, &u.Role, &u.AvatarAsset, &u.DisplayName, &u.Status, &u.CreatedAt); err == nil {
			u.PasswordHash = ""
			list = append(list, u)
		}
	}
	return list
}

func GetUserByUsername(username string) (*User, bool) {
	dbLock.RLock()
	defer dbLock.RUnlock()

	var u User
	err := db.QueryRow(`
		SELECT id, username, password_hash, role, avatar_asset, display_name, status, created_at
		FROM users WHERE username = ?
	`, username).Scan(&u.ID, &u.Username, &u.PasswordHash, &u.Role, &u.AvatarAsset, &u.DisplayName, &u.Status, &u.CreatedAt)

	if err != nil {
		return nil, false
	}
	u.PasswordHash = ""
	return &u, true
}

func UpdateProfile(username, displayName, status, avatar string) bool {
	dbLock.Lock()
	defer dbLock.Unlock()

	res, err := db.Exec(`
		UPDATE users 
		SET display_name = ?, status = ?, avatar_asset = ?
		WHERE username = ?
	`, displayName, status, avatar, username)

	if err != nil {
		return false
	}

	rows, err := res.RowsAffected()
	return err == nil && rows > 0
}

func ChangePassword(username, oldPassword, newPassword string) error {
	dbLock.Lock()
	defer dbLock.Unlock()

	var hash string
	if err := db.QueryRow(`SELECT password_hash FROM users WHERE username = ?`, username).Scan(&hash); err != nil {
		return os.ErrNotExist
	}

	if err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(oldPassword)); err != nil {
		return os.ErrPermission
	}

	if len(newPassword) < 4 {
		return os.ErrInvalid
	}

	newHash, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	_, err = db.Exec(`UPDATE users SET password_hash = ? WHERE username = ?`, string(newHash), username)
	return err
}
