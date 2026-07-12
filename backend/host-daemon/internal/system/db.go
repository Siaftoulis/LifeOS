package system

import (
	"database/sql"
	"fmt"
	"log"
	"path/filepath"

	_ "modernc.org/sqlite"
)

var DB *sql.DB

func InitDB(dataDir string) error {
	dbPath := filepath.Join(dataDir, "system.db")
	log.Printf("Initializing system database at %s", dbPath)

	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return fmt.Errorf("failed to open system db: %v", err)
	}

	DB = db

	return createTables()
}

func createTables() error {
	query := `
	CREATE TABLE IF NOT EXISTS tailscale_nodes (
		id TEXT PRIMARY KEY,
		hostname TEXT NOT NULL,
		ip TEXT NOT NULL,
		status TEXT NOT NULL,
		last_seen INTEGER NOT NULL
	);
	`

	_, err := DB.Exec(query)
	if err != nil {
		return fmt.Errorf("failed to create system tables: %v", err)
	}

	// Seed data
	var count int
	err = DB.QueryRow("SELECT COUNT(*) FROM tailscale_nodes").Scan(&count)
	if err == nil && count == 0 {
		seedNodes()
	}

	return nil
}

func seedNodes() {
	nodes := []struct {
		ID       string
		Hostname string
		IP       string
		Status   string
	}{
		{"node_1", "desktop-main", "100.100.100.1", "ONLINE"},
		{"node_2", "phone-pds", "100.100.100.2", "OFFLINE"},
	}

	for _, n := range nodes {
		_, err := DB.Exec("INSERT INTO tailscale_nodes (id, hostname, ip, status, last_seen) VALUES (?, ?, ?, ?, strftime('%s', 'now'))",
			n.ID, n.Hostname, n.IP, n.Status)
		if err != nil {
			log.Printf("Failed to seed node: %v", err)
		}
	}
}
