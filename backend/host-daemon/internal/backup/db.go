package backup

import (
	"database/sql"
	"fmt"
	"log"
	"path/filepath"
	"time"

	_ "modernc.org/sqlite"
)

var DB *sql.DB

func InitDB(dataDir string) error {
	dbPath := filepath.Join(dataDir, "backup.db")
	log.Printf("Initializing backup database at %s", dbPath)

	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return fmt.Errorf("failed to open backup db: %v", err)
	}

	DB = db

	return createTables()
}

func createTables() error {
	query := `
	CREATE TABLE IF NOT EXISTS device_backups (
		id TEXT PRIMARY KEY,
		device_id TEXT NOT NULL,
		name TEXT NOT NULL,
		last_backup INTEGER NOT NULL,
		backup_status TEXT NOT NULL
	);
	`

	_, err := DB.Exec(query)
	if err != nil {
		return fmt.Errorf("failed to create backup tables: %v", err)
	}

	// Seed data
	var count int
	err = DB.QueryRow("SELECT COUNT(*) FROM device_backups").Scan(&count)
	if err == nil && count == 0 {
		seedBackups()
	}

	return nil
}

func seedBackups() {
	_, err := DB.Exec("INSERT INTO device_backups (id, device_id, name, last_backup, backup_status) VALUES (?, ?, ?, ?, ?)",
		"b1", "device_1", "PC Auto Backup", time.Now().Unix()-86400, "COMPLETED")
	if err != nil {
		log.Printf("Failed to seed backup: %v", err)
	}
}

func AddBackupRecord(filename, deviceId string) error {
	_, err := DB.Exec("INSERT INTO device_backups (id, device_id, name, last_backup, backup_status) VALUES (?, ?, ?, ?, ?)",
		filename, deviceId, filename, time.Now().Unix(), "COMPLETED")
	return err
}
