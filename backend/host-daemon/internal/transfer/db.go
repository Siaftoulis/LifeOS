package transfer

import (
	"database/sql"
	"fmt"
	"log"
	"path/filepath"

	_ "modernc.org/sqlite"
)

var DB *sql.DB

func InitDB(dataDir string) error {
	dbPath := filepath.Join(dataDir, "transfer.db")
	log.Printf("Initializing transfer database at %s", dbPath)

	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return fmt.Errorf("failed to open transfer db: %v", err)
	}

	DB = db

	if err := createTables(); err != nil {
		return err
	}
	return nil
}

func createTables() error {
	query := `
	CREATE TABLE IF NOT EXISTS transfers (
		transfer_id TEXT PRIMARY KEY,
		file_id TEXT NOT NULL,
		filename TEXT NOT NULL,
		file_size INTEGER NOT NULL,
		file_hash TEXT NOT NULL,
		chunk_size INTEGER NOT NULL,
		total_chunks INTEGER NOT NULL,
		received_chunks TEXT DEFAULT '[]',
		verified_chunks TEXT DEFAULT '[]',
		state TEXT NOT NULL DEFAULT 'CREATED',
		mime_type TEXT,
		metadata TEXT,
		filepath TEXT,
		created_at INTEGER NOT NULL,
		updated_at INTEGER NOT NULL
	);
	CREATE INDEX IF NOT EXISTS idx_transfers_state ON transfers(state);
	CREATE INDEX IF NOT EXISTS idx_transfers_file_id ON transfers(file_id);
	`

	_, err := DB.Exec(query)
	if err != nil {
		return fmt.Errorf("failed to create transfers table: %v", err)
	}

	query = `
	CREATE TABLE IF NOT EXISTS transfer_chunks (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		transfer_id TEXT NOT NULL,
		chunk_index INTEGER NOT NULL,
		offset INTEGER NOT NULL,
		length INTEGER NOT NULL,
		hash TEXT NOT NULL,
		state TEXT NOT NULL DEFAULT 'PENDING',
		filepath TEXT,
		retry_count INTEGER DEFAULT 0,
		uploaded_at INTEGER,
		verified_at INTEGER,
		FOREIGN KEY(transfer_id) REFERENCES transfers(transfer_id) ON DELETE CASCADE
	);
	CREATE INDEX IF NOT EXISTS idx_transfer_chunks_transfer ON transfer_chunks(transfer_id);
	CREATE UNIQUE INDEX IF NOT EXISTS idx_transfer_chunks_unique ON transfer_chunks(transfer_id, chunk_index);
	`

	_, err = DB.Exec(query)
	if err != nil {
		return fmt.Errorf("failed to create transfer_chunks table: %v", err)
	}

	return nil
}