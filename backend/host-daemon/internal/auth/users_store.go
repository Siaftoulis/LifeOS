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
}

func seedAdminIfNeeded() {
	dbLock.Lock()
	defer dbLock.Unlock()

	var count int
	err := db.QueryRow("SELECT COUNT(*) FROM users").Scan(&count)
	if err != nil || count > 0 {
		return
	}

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

	_, err = db.Exec(`
		INSERT INTO users (id, username, password_hash, role, avatar_asset, display_name, status, created_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)
	`, admin.ID, admin.Username, admin.PasswordHash, admin.Role, admin.AvatarAsset, admin.DisplayName, admin.Status, admin.CreatedAt)
	if err != nil {
		log.Printf("Error seeding admin in SQLite: %v", err)
	}
}
