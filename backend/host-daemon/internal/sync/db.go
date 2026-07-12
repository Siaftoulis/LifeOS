package sync

import (
	"database/sql"
	"fmt"
	"log"
	"path/filepath"

	_ "modernc.org/sqlite"
)

var DB *sql.DB

func InitDB(dataDir string) error {
	dbPath := filepath.Join(dataDir, "sync.db")
	log.Printf("Initializing sync database at %s", dbPath)

	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return fmt.Errorf("failed to open sync db: %v", err)
	}

	DB = db

	return createTables()
}

func createTables() error {
	query := `
	CREATE TABLE IF NOT EXISTS conflict_logs (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		table_name TEXT NOT NULL,
		record_id TEXT NOT NULL,
		resolution TEXT NOT NULL,
		timestamp INTEGER NOT NULL
	);
	`

	_, err := DB.Exec(query)
	if err != nil {
		return fmt.Errorf("failed to create sync tables: %v", err)
	}

	return nil
}
