package vm

import (
	"database/sql"
	"fmt"
	"log"
	"path/filepath"

	_ "modernc.org/sqlite"
)

var DB *sql.DB

func InitDB(dataDir string) error {
	dbPath := filepath.Join(dataDir, "vm.db")
	log.Printf("Initializing VM database at %s", dbPath)

	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return fmt.Errorf("failed to open vm db: %v", err)
	}

	DB = db

	return createTables()
}

func createTables() error {
	query := `
	CREATE TABLE IF NOT EXISTS virtual_machines (
		id TEXT PRIMARY KEY,
		name TEXT NOT NULL,
		type TEXT NOT NULL,
		state TEXT NOT NULL,
		ram INTEGER NOT NULL
	);
	`

	_, err := DB.Exec(query)
	if err != nil {
		return fmt.Errorf("failed to create vm tables: %v", err)
	}

	// Seed data
	var count int
	err = DB.QueryRow("SELECT COUNT(*) FROM virtual_machines").Scan(&count)
	if err == nil && count == 0 {
		seedVMs()
	}

	return nil
}

func seedVMs() {
	vms := []struct {
		ID    string
		Name  string
		Type  string
		State string
		RAM   int
	}{
		{"vm_1", "Dev-Sandbox", "MICROVM", "RUNNING", 2048},
		{"vm_2", "Database-Local", "CONTAINER", "RUNNING", 1024},
		{"vm_3", "Windows-Game", "DESKTOP", "STOPPED", 8192},
	}

	for _, v := range vms {
		_, err := DB.Exec("INSERT INTO virtual_machines (id, name, type, state, ram) VALUES (?, ?, ?, ?, ?)",
			v.ID, v.Name, v.Type, v.State, v.RAM)
		if err != nil {
			log.Printf("Failed to seed vm: %v", err)
		}
	}
}
