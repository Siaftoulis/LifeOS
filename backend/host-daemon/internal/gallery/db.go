package gallery

import (
	"database/sql"
	"fmt"
	"log"
	"path/filepath"

	_ "modernc.org/sqlite"
)

var DB *sql.DB

func InitDB(dataDir string) error {
	dbPath := filepath.Join(dataDir, "gallery.db")
	log.Printf("Initializing gallery database at %s", dbPath)

	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return fmt.Errorf("failed to open gallery db: %v", err)
	}

	DB = db

	return createTables()
}

func createTables() error {
	query := `
	CREATE TABLE IF NOT EXISTS assets (
		id TEXT PRIMARY KEY,
		user_id TEXT NOT NULL,
		device_id TEXT NOT NULL,
		filename TEXT NOT NULL,
		type TEXT NOT NULL,
		created_at DATETIME NOT NULL,
		size_bytes INTEGER NOT NULL,
		filepath TEXT NOT NULL
	);
	`

	_, err := DB.Exec(query)
	if err != nil {
		return fmt.Errorf("failed to create assets table: %v", err)
	}

	return nil
}
