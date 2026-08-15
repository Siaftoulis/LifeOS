package zen

import (
	"database/sql"
	"fmt"
	"log"
	"path/filepath"

	_ "modernc.org/sqlite"
)

var DB *sql.DB

func InitDB(dataDir string) error {
	dbPath := filepath.Join(dataDir, "zen.db")
	log.Printf("Initializing zen database at %s", dbPath)

	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return fmt.Errorf("failed to open zen db: %v", err)
	}

	DB = db

	query := `
	CREATE TABLE IF NOT EXISTS zen_nodes (
		id TEXT PRIMARY KEY,
		name TEXT NOT NULL,
		path TEXT UNIQUE NOT NULL,
		is_directory INTEGER NOT NULL DEFAULT 0,
		parent_id TEXT DEFAULT '',
		created_at INTEGER NOT NULL,
		updated_at INTEGER NOT NULL
	);
	CREATE TABLE IF NOT EXISTS zen_documents (
		id TEXT PRIMARY KEY,
		node_id TEXT NOT NULL,
		text_content TEXT NOT NULL DEFAULT '',
		updated_at INTEGER NOT NULL
	);
	CREATE TABLE IF NOT EXISTS zen_tombstones (
		path TEXT PRIMARY KEY,
		at INTEGER NOT NULL
	);
	`

	_, err = db.Exec(query)
	if err != nil {
		return fmt.Errorf("failed to create zen tables: %v", err)
	}

	return nil
}
