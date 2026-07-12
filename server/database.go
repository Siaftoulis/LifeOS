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
	`
	_, err := db.Exec(query)
	if err != nil {
		log.Fatalf("Error creating tables: %v", err)
	}
}

// Add useful helper functions here as needed
