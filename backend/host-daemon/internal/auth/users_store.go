package auth

import (
	"database/sql"
	"log"
	"os"
	"sync"
	"time"

	"golang.org/x/crypto/bcrypt"
	_ "modernc.org/sqlite"
)

var (
	dbLock sync.RWMutex
	db     *sql.DB
)

func init() {
	if err := os.MkdirAll("./data", 0755); err != nil {
		log.Printf("Error creating data directory: %v", err)
	}

	var err error
	db, err = sql.Open("sqlite", "./data/lifeos.db")
	if err != nil {
		log.Fatalf("Error opening SQLite database: %v", err)
	}

	initTables()
	seedAdminIfNeeded()
}

func initTables() {
	query := `
	CREATE TABLE IF NOT EXISTS users (
		id TEXT PRIMARY KEY,
		username TEXT UNIQUE,
		email TEXT,
		password_hash TEXT,
		role TEXT,
		avatar_asset TEXT,
		display_name TEXT,
		status TEXT,
		created_at INTEGER
	);`
	_, err := db.Exec(query)
	if err != nil {
		log.Fatalf("Error creating users table in SQLite: %v", err)
	}

	// Safe migration: add email column if it doesn't exist yet
	_, _ = db.Exec("ALTER TABLE users ADD COLUMN email TEXT;")
}

func seedAdminIfNeeded() {
	dbLock.Lock()
	defer dbLock.Unlock()

	// Seed / update panospds
	var countPanos int
	_ = db.QueryRow("SELECT COUNT(*) FROM users WHERE username = 'panospds'").Scan(&countPanos)
	if countPanos == 0 {
		hash, err := bcrypt.GenerateFromPassword([]byte("1897"), bcrypt.DefaultCost)
		if err == nil {
			admin := User{
				ID:           "u-admin-1",
				Username:     "panospds",
				Email:        "panagiotissiaftoulis@gmail.com",
				PasswordHash: string(hash),
				Role:         "ADMIN",
				AvatarAsset:  "",
				DisplayName:  "Panos PDS",
				Status:       "System Administrator",
				CreatedAt:    time.Now().Unix(),
			}
			_, _ = db.Exec(`
				INSERT INTO users (id, username, email, password_hash, role, avatar_asset, display_name, status, created_at)
				VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
			`, admin.ID, admin.Username, admin.Email, admin.PasswordHash, admin.Role, admin.AvatarAsset, admin.DisplayName, admin.Status, admin.CreatedAt)
		}
	} else {
		_, _ = db.Exec("UPDATE users SET email = 'panagiotissiaftoulis@gmail.com' WHERE username = 'panospds' AND (email IS NULL OR email = '')")
	}

	// Seed / update annadim
	var countAnna int
	_ = db.QueryRow("SELECT COUNT(*) FROM users WHERE username = 'annadim'").Scan(&countAnna)
	if countAnna == 0 {
		hash, err := bcrypt.GenerateFromPassword([]byte("1234"), bcrypt.DefaultCost)
		if err == nil {
			anna := User{
				ID:           "u-anna-2",
				Username:     "annadim",
				Email:        "adimopoulou1234@gmail.com",
				PasswordHash: string(hash),
				Role:         "USER",
				AvatarAsset:  "",
				DisplayName:  "Anna Dimopoulou",
				Status:       "Family Member",
				CreatedAt:    time.Now().Unix(),
			}
			_, _ = db.Exec(`
				INSERT INTO users (id, username, email, password_hash, role, avatar_asset, display_name, status, created_at)
				VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
			`, anna.ID, anna.Username, anna.Email, anna.PasswordHash, anna.Role, anna.AvatarAsset, anna.DisplayName, anna.Status, anna.CreatedAt)
		}
	} else {
		_, _ = db.Exec("UPDATE users SET email = 'adimopoulou1234@gmail.com' WHERE username = 'annadim' AND (email IS NULL OR email = '')")
	}
}
