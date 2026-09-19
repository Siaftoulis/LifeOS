package auth

import (
	"database/sql"
	"fmt"
	"os"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"
)

func AuthenticateUser(username, password string) (*User, bool) {
	dbLock.RLock()
	defer dbLock.RUnlock()

	var u User
	var email sql.NullString
	err := db.QueryRow(`
		SELECT id, username, COALESCE(email, ''), password_hash, role, avatar_asset, display_name, status, created_at
		FROM users WHERE username = ?
	`, username).Scan(&u.ID, &u.Username, &email, &u.PasswordHash, &u.Role, &u.AvatarAsset, &u.DisplayName, &u.Status, &u.CreatedAt)

	if err != nil {
		return nil, false
	}
	u.Email = email.String

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
		Email:        "",
		PasswordHash: string(hash),
		Role:         role,
		AvatarAsset:  "",
		DisplayName:  username,
		Status:       "Available",
		CreatedAt:    time.Now().Unix(),
	}

	_, err = db.Exec(`
		INSERT INTO users (id, username, email, password_hash, role, avatar_asset, display_name, status, created_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
	`, newUser.ID, newUser.Username, newUser.Email, newUser.PasswordHash, newUser.Role, newUser.AvatarAsset, newUser.DisplayName, newUser.Status, newUser.CreatedAt)

	if err != nil {
		return nil, err
	}

	return &newUser, nil
}

func GetUsers() []User {
	dbLock.RLock()
	defer dbLock.RUnlock()

	rows, err := db.Query(`
		SELECT id, username, COALESCE(email, ''), password_hash, role, avatar_asset, display_name, status, created_at
		FROM users
	`)
	if err != nil {
		return nil
	}
	defer rows.Close()

	var list []User
	for rows.Next() {
		var u User
		var email sql.NullString
		if err := rows.Scan(&u.ID, &u.Username, &email, &u.PasswordHash, &u.Role, &u.AvatarAsset, &u.DisplayName, &u.Status, &u.CreatedAt); err == nil {
			u.Email = email.String
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
	var email sql.NullString
	err := db.QueryRow(`
		SELECT id, username, COALESCE(email, ''), password_hash, role, avatar_asset, display_name, status, created_at
		FROM users WHERE username = ?
	`, username).Scan(&u.ID, &u.Username, &email, &u.PasswordHash, &u.Role, &u.AvatarAsset, &u.DisplayName, &u.Status, &u.CreatedAt)

	if err != nil {
		return nil, false
	}
	u.Email = email.String
	u.PasswordHash = ""
	return &u, true
}

func GetUserByEmail(email string) (*User, bool) {
	if email == "" {
		return nil, false
	}
	dbLock.RLock()
	defer dbLock.RUnlock()

	var u User
	var userEmail sql.NullString
	err := db.QueryRow(`
		SELECT id, username, COALESCE(email, ''), password_hash, role, avatar_asset, display_name, status, created_at
		FROM users WHERE LOWER(email) = LOWER(?)
	`, email).Scan(&u.ID, &u.Username, &userEmail, &u.PasswordHash, &u.Role, &u.AvatarAsset, &u.DisplayName, &u.Status, &u.CreatedAt)

	if err != nil {
		return nil, false
	}
	u.Email = userEmail.String
	u.PasswordHash = ""
	return &u, true
}

func AutoProvisionOAuthUser(provider, externalID, displayName string) (*User, error) {
	dbLock.Lock()
	defer dbLock.Unlock()

	var username string
	var email string
	if provider == "google" {
		email = strings.ToLower(externalID)
		parts := strings.Split(email, "@")
		username = parts[0]
	} else {
		username = strings.ToLower(externalID)
		email = ""
	}

	// Check if already exists by username
	var existing User
	var exEmail sql.NullString
	err := db.QueryRow(`
		SELECT id, username, COALESCE(email, ''), role, avatar_asset, display_name, status, created_at
		FROM users WHERE username = ?
	`, username).Scan(&existing.ID, &existing.Username, &exEmail, &existing.Role, &existing.AvatarAsset, &existing.DisplayName, &existing.Status, &existing.CreatedAt)
	if err == nil {
		existing.Email = exEmail.String
		if email != "" && existing.Email == "" {
			_, _ = db.Exec("UPDATE users SET email = ? WHERE id = ?", email, existing.ID)
			existing.Email = email
		}
		return &existing, nil
	}

	if displayName == "" {
		displayName = username
	}

	newUser := User{
		ID:          "u-" + time.Now().Format("20060102150405"),
		Username:    username,
		Email:       email,
		Role:        "USER",
		AvatarAsset: "",
		DisplayName: displayName,
		Status:      "Connected via " + strings.ToUpper(provider),
		CreatedAt:   time.Now().Unix(),
	}

	_, err = db.Exec(`
		INSERT INTO users (id, username, email, password_hash, role, avatar_asset, display_name, status, created_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
	`, newUser.ID, newUser.Username, newUser.Email, "", newUser.Role, newUser.AvatarAsset, newUser.DisplayName, newUser.Status, newUser.CreatedAt)
	if err != nil {
		return nil, err
	}

	return &newUser, nil
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

func DeleteUser(username string) error {
	dbLock.Lock()
	defer dbLock.Unlock()

	if username == "panospds" {
		return fmt.Errorf("cannot delete root administrator")
	}

	res, err := db.Exec("DELETE FROM users WHERE username = ?", username)
	if err != nil {
		return err
	}
	rows, err := res.RowsAffected()
	if err != nil || rows == 0 {
		return os.ErrNotExist
	}
	return nil
}

func UpdateUser(username, role, displayName, email, status string) (*User, error) {
	dbLock.Lock()
	defer dbLock.Unlock()

	_, err := db.Exec(`
		UPDATE users
		SET role = COALESCE(NULLIF(?, ''), role),
		    display_name = COALESCE(NULLIF(?, ''), display_name),
		    email = COALESCE(NULLIF(?, ''), email),
		    status = COALESCE(NULLIF(?, ''), status)
		WHERE username = ?
	`, role, displayName, email, status, username)
	if err != nil {
		return nil, err
	}

	var u User
	var exEmail sql.NullString
	err = db.QueryRow(`
		SELECT id, username, COALESCE(email, ''), role, avatar_asset, display_name, status, created_at
		FROM users WHERE username = ?
	`, username).Scan(&u.ID, &u.Username, &exEmail, &u.Role, &u.AvatarAsset, &u.DisplayName, &u.Status, &u.CreatedAt)
	if err != nil {
		return nil, err
	}
	u.Email = exEmail.String
	return &u, nil
}
