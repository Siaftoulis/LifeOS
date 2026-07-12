package darkweb

import (
	"database/sql"
	"fmt"
	"log"
	"path/filepath"

	_ "modernc.org/sqlite"
)

var DB *sql.DB

func InitDB(dataDir string) error {
	dbPath := filepath.Join(dataDir, "darkweb.db")
	log.Printf("Initializing darkweb database at %s", dbPath)

	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return fmt.Errorf("failed to open darkweb db: %v", err)
	}

	DB = db

	return createTables()
}

func createTables() error {
	query := `
	CREATE TABLE IF NOT EXISTS torrents (
		info_hash TEXT PRIMARY KEY,
		name TEXT NOT NULL,
		status TEXT NOT NULL,
		progress REAL NOT NULL
	);
	`

	_, err := DB.Exec(query)
	if err != nil {
		return fmt.Errorf("failed to create darkweb tables: %v", err)
	}

	// Seed data
	var count int
	err = DB.QueryRow("SELECT COUNT(*) FROM torrents").Scan(&count)
	if err == nil && count == 0 {
		seedDarkWeb()
	}

	return nil
}

func seedDarkWeb() {
	torrents := []struct {
		InfoHash string
		Name     string
		Status   string
		Progress float64
	}{
		{"deadbeef12345", "Ubuntu 24.04 ISO", "SEEDING", 1.0},
		{"cafe123456789", "Debian 12 Netinst", "DOWNLOADING", 0.45},
	}

	for _, t := range torrents {
		_, err := DB.Exec("INSERT INTO torrents (info_hash, name, status, progress) VALUES (?, ?, ?, ?)",
			t.InfoHash, t.Name, t.Status, t.Progress)
		if err != nil {
			log.Printf("Failed to seed torrent: %v", err)
		}
	}
}
