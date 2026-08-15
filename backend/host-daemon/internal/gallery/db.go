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

	if err := createTables(); err != nil {
		return err
	}
	return migrate()
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

// migrate adds smart-picker columns to existing databases. ALTER TABLE fails
// silently if a column already exists.
func migrate() error {
	cols := []struct{ name, typ string }{
		{"hash", "TEXT DEFAULT ''"},
		{"width", "INTEGER DEFAULT 0"},
		{"height", "INTEGER DEFAULT 0"},
		{"source", "TEXT DEFAULT ''"},
		{"title", "TEXT DEFAULT ''"},
		{"tags", "TEXT DEFAULT '[]'"},
		{"colors", "TEXT DEFAULT '[]'"},
		{"lat", "REAL DEFAULT 0"},
		{"lng", "REAL DEFAULT 0"},
		{"place", "TEXT DEFAULT ''"},
	}
	for _, c := range cols {
		if _, err := DB.Exec(fmt.Sprintf("ALTER TABLE assets ADD COLUMN %s %s", c.name, c.typ)); err != nil {
			log.Printf("gallery migrate: column %s: %v", c.name, err)
		}
	}
	return nil
}
