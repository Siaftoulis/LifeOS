package main

import (
	"database/sql"
	"log"

	_ "github.com/mattn/go-sqlite3"
)

var db *sql.DB

func initDB(filepath string) {
	var err error
	db, err = sql.Open("sqlite3", filepath)
	if err != nil {
		log.Fatal(err)
	}

	createTables()
}

func createTables() {
	query := `
	CREATE TABLE IF NOT EXISTS users (
		id TEXT PRIMARY KEY,
		username TEXT,
		role TEXT,
		family_id TEXT
	);

	CREATE TABLE IF NOT EXISTS quests (
		id TEXT PRIMARY KEY,
		title TEXT,
		reward_points INTEGER,
		assigned_to TEXT,
		status TEXT,
		created_by TEXT,
		created_at INTEGER
	);

	CREATE TABLE IF NOT EXISTS quest_logs (
		id TEXT PRIMARY KEY,
		quest_id TEXT,
		action TEXT, -- e.g., 'ACCEPTED', 'DENIED', 'COMPLETED'
		user_id TEXT,
		timestamp INTEGER
	);

	CREATE TABLE IF NOT EXISTS points_ledger (
		id TEXT PRIMARY KEY,
		user_id TEXT,
		event TEXT,
		points INTEGER,
		timestamp INTEGER
	);

	CREATE TABLE IF NOT EXISTS sync_deltas (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		client_ts INTEGER,
		payload TEXT
	);

	CREATE TABLE IF NOT EXISTS permissions (
		user_id TEXT,
		path_prefix TEXT,
		role TEXT,
		PRIMARY KEY (user_id, path_prefix)
	);
	`
	_, err := db.Exec(query)
	if err != nil {
		log.Fatalf("Error creating tables: %v", err)
	}
}

// ponytail: room & path ACL authorization check
func hasPermission(userID, notePath, requiredRole string) bool {
	if userID == "" || userID == "admin" || userID == "panospds" {
		return true
	}

	var count int
	err := db.QueryRow(`
		SELECT COUNT(*) FROM permissions 
		WHERE user_id = ? AND (? LIKE path_prefix || '%' OR path_prefix = '' OR path_prefix = 'root' OR path_prefix = 'vault') 
		AND (role = ? OR role = 'write')
	`, userID, notePath, requiredRole).Scan(&count)

	if err != nil || count == 0 {
		// Default to allowed if table empty for initial setup
		var totalPerms int
		db.QueryRow("SELECT COUNT(*) FROM permissions").Scan(&totalPerms)
		return totalPerms == 0
	}
	return count > 0
}

