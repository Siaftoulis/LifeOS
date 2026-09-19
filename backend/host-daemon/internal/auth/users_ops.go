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
	var frame sql.NullString
	var nameStyle sql.NullString
	err := db.QueryRow(`
		SELECT id, username, COALESCE(email, ''), password_hash, role, avatar_asset, COALESCE(frame, 'none'), display_name, status, COALESCE(name_style, 'default'), created_at
		FROM users WHERE username = ?
	`, username).Scan(&u.ID, &u.Username, &email, &u.PasswordHash, &u.Role, &u.AvatarAsset, &frame, &u.DisplayName, &u.Status, &nameStyle, &u.CreatedAt)

	if err != nil {
		return nil, false
	}
	u.Email = email.String
	u.Frame = frame.String
	u.NameStyle = nameStyle.String

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
		Frame:        "none",
		DisplayName:  username,
		Status:       "Available",
		NameStyle:    "default",
		CreatedAt:    time.Now().Unix(),
	}

	_, err = db.Exec(`
		INSERT INTO users (id, username, email, password_hash, role, avatar_asset, frame, display_name, status, name_style, created_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	`, newUser.ID, newUser.Username, newUser.Email, newUser.PasswordHash, newUser.Role, newUser.AvatarAsset, newUser.Frame, newUser.DisplayName, newUser.Status, newUser.NameStyle, newUser.CreatedAt)

	if err != nil {
		return nil, err
	}

	return &newUser, nil
}

func GetUsers() []User {
	dbLock.RLock()
	defer dbLock.RUnlock()

	rows, err := db.Query(`
		SELECT id, username, COALESCE(email, ''), password_hash, role, avatar_asset, COALESCE(frame, 'none'), display_name, status, COALESCE(name_style, 'default'), created_at
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
		var frame sql.NullString
		var nameStyle sql.NullString
		if err := rows.Scan(&u.ID, &u.Username, &email, &u.PasswordHash, &u.Role, &u.AvatarAsset, &frame, &u.DisplayName, &u.Status, &nameStyle, &u.CreatedAt); err == nil {
			u.Email = email.String
			u.Frame = frame.String
			u.NameStyle = nameStyle.String
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
	var frame sql.NullString
	var nameStyle sql.NullString
	err := db.QueryRow(`
		SELECT id, username, COALESCE(email, ''), password_hash, role, avatar_asset, COALESCE(frame, 'none'), display_name, status, COALESCE(name_style, 'default'), created_at
		FROM users WHERE username = ?
	`, username).Scan(&u.ID, &u.Username, &email, &u.PasswordHash, &u.Role, &u.AvatarAsset, &frame, &u.DisplayName, &u.Status, &nameStyle, &u.CreatedAt)

	if err != nil {
		return nil, false
	}
	u.Email = email.String
	u.Frame = frame.String
	u.NameStyle = nameStyle.String
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
	var frame sql.NullString
	var nameStyle sql.NullString
	err := db.QueryRow(`
		SELECT id, username, COALESCE(email, ''), password_hash, role, avatar_asset, COALESCE(frame, 'none'), display_name, status, COALESCE(name_style, 'default'), created_at
		FROM users WHERE LOWER(email) = LOWER(?)
	`, email).Scan(&u.ID, &u.Username, &userEmail, &u.PasswordHash, &u.Role, &u.AvatarAsset, &frame, &u.DisplayName, &u.Status, &nameStyle, &u.CreatedAt)

	if err != nil {
		return nil, false
	}
	u.Email = userEmail.String
	u.Frame = frame.String
	u.NameStyle = nameStyle.String
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
	var frame sql.NullString
	var nameStyle sql.NullString
	err := db.QueryRow(`
		SELECT id, username, COALESCE(email, ''), role, avatar_asset, COALESCE(frame, 'none'), display_name, status, COALESCE(name_style, 'default'), created_at
		FROM users WHERE username = ?
	`, username).Scan(&existing.ID, &existing.Username, &exEmail, &existing.Role, &existing.AvatarAsset, &frame, &existing.DisplayName, &existing.Status, &nameStyle, &existing.CreatedAt)
	if err == nil {
		existing.Email = exEmail.String
		existing.Frame = frame.String
		existing.NameStyle = nameStyle.String
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
		Frame:       "none",
		DisplayName: displayName,
		Status:      "Connected via " + strings.ToUpper(provider),
		NameStyle:   "default",
		CreatedAt:   time.Now().Unix(),
	}

	_, err = db.Exec(`
		INSERT INTO users (id, username, email, password_hash, role, avatar_asset, frame, display_name, status, name_style, created_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	`, newUser.ID, newUser.Username, newUser.Email, "", newUser.Role, newUser.AvatarAsset, newUser.Frame, newUser.DisplayName, newUser.Status, newUser.NameStyle, newUser.CreatedAt)
	if err != nil {
		return nil, err
	}

	return &newUser, nil
}

func UpdateProfile(currentUsername, newUsername, displayName, status, avatar, frame, nameStyle string) (*User, error) {
	dbLock.Lock()
	defer dbLock.Unlock()

	targetUsername := currentUsername
	if newUsername != "" && newUsername != currentUsername {
		newUsername = strings.TrimSpace(newUsername)
		var count int
		_ = db.QueryRow("SELECT COUNT(*) FROM users WHERE username = ? AND username != ?", newUsername, currentUsername).Scan(&count)
		if count > 0 {
			return nil, fmt.Errorf("username '%s' is already taken", newUsername)
		}
		targetUsername = newUsername
	}

	if frame == "" {
		frame = "none"
	}
	if nameStyle == "" {
		nameStyle = "default"
	}

	_, err := db.Exec(`
		UPDATE users 
		SET username = ?, display_name = ?, status = ?, avatar_asset = ?, frame = ?, name_style = ?
		WHERE username = ?
	`, targetUsername, displayName, status, avatar, frame, nameStyle, currentUsername)

	if err != nil {
		return nil, err
	}

	var u User
	var email sql.NullString
	var f sql.NullString
	var ns sql.NullString
	err = db.QueryRow(`
		SELECT id, username, COALESCE(email, ''), role, avatar_asset, COALESCE(frame, 'none'), display_name, status, COALESCE(name_style, 'default'), created_at
		FROM users WHERE username = ?
	`, targetUsername).Scan(&u.ID, &u.Username, &email, &u.Role, &u.AvatarAsset, &f, &u.DisplayName, &u.Status, &ns, &u.CreatedAt)
	if err != nil {
		return nil, err
	}
	u.Email = email.String
	u.Frame = f.String
	u.NameStyle = ns.String
	return &u, nil
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

func UpdateUser(username, role, displayName, email, status, password string) (*User, error) {
	dbLock.Lock()
	defer dbLock.Unlock()

	var passwordHash string
	if password != "" {
		hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
		if err == nil {
			passwordHash = string(hash)
		}
	}

	_, err := db.Exec(`
		UPDATE users
		SET role = COALESCE(NULLIF(?, ''), role),
		    display_name = COALESCE(NULLIF(?, ''), display_name),
		    email = COALESCE(NULLIF(?, ''), email),
		    status = COALESCE(NULLIF(?, ''), status),
		    password_hash = COALESCE(NULLIF(?, ''), password_hash)
		WHERE username = ?
	`, role, displayName, email, status, passwordHash, username)
	if err != nil {
		return nil, err
	}

	var u User
	var exEmail sql.NullString
	var frame sql.NullString
	var nameStyle sql.NullString
	err = db.QueryRow(`
		SELECT id, username, COALESCE(email, ''), role, avatar_asset, COALESCE(frame, 'none'), display_name, status, COALESCE(name_style, 'default'), created_at
		FROM users WHERE username = ?
	`, username).Scan(&u.ID, &u.Username, &exEmail, &u.Role, &u.AvatarAsset, &frame, &u.DisplayName, &u.Status, &nameStyle, &u.CreatedAt)
	if err != nil {
		return nil, err
	}
	u.Email = exEmail.String
	u.Frame = frame.String
	u.NameStyle = nameStyle.String
	return &u, nil
}
