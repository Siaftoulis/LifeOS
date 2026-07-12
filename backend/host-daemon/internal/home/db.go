package home

import (
	"database/sql"
	"fmt"
	"log"
	"path/filepath"

	_ "modernc.org/sqlite"
)

var DB *sql.DB

func InitDB(dataDir string) error {
	dbPath := filepath.Join(dataDir, "home.db")
	log.Printf("Initializing home database at %s", dbPath)

	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return fmt.Errorf("failed to open home db: %v", err)
	}

	DB = db

	return createTables()
}

func createTables() error {
	query := `
	CREATE TABLE IF NOT EXISTS devices (
		id TEXT PRIMARY KEY,
		name TEXT NOT NULL,
		type TEXT NOT NULL,
		state TEXT NOT NULL,
		updated_at INTEGER NOT NULL
	);
	
	CREATE TABLE IF NOT EXISTS sensor_logs (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		sensor_id TEXT NOT NULL,
		value TEXT NOT NULL,
		timestamp INTEGER NOT NULL
	);
	`

	_, err := DB.Exec(query)
	if err != nil {
		return fmt.Errorf("failed to create home tables: %v", err)
	}

	// Seed data
	var count int
	err = DB.QueryRow("SELECT COUNT(*) FROM devices").Scan(&count)
	if err == nil && count == 0 {
		seedHome()
	}

	return nil
}

func seedHome() {
	devices := []struct {
		ID    string
		Name  string
		Type  string
		State string
	}{
		{"light.living_room", "Living Room Light", "light", "ON"},
		{"light.bedroom", "Bedroom Light", "light", "OFF"},
		{"climate.thermostat", "Main Thermostat", "climate", "HEAT"},
		{"lock.front_door", "Front Door", "lock", "LOCKED"},
	}

	for _, d := range devices {
		_, err := DB.Exec("INSERT INTO devices (id, name, type, state, updated_at) VALUES (?, ?, ?, ?, strftime('%s', 'now'))",
			d.ID, d.Name, d.Type, d.State)
		if err != nil {
			log.Printf("Failed to seed home device: %v", err)
		}
	}
}
