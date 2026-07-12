package youtube

import (
	"database/sql"
	"fmt"
	"log"
	"path/filepath"

	_ "modernc.org/sqlite"
)

var DB *sql.DB

func InitDB(dataDir string) error {
	dbPath := filepath.Join(dataDir, "youtube.db")
	log.Printf("Initializing YouTube database at %s", dbPath)

	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return fmt.Errorf("failed to open youtube db: %v", err)
	}

	DB = db

	return createTables()
}

func createTables() error {
	query := `
	CREATE TABLE IF NOT EXISTS videos (
		id TEXT PRIMARY KEY,
		title TEXT NOT NULL,
		size TEXT NOT NULL
	);
	`

	_, err := DB.Exec(query)
	if err != nil {
		return fmt.Errorf("failed to create youtube tables: %v", err)
	}

	// Seed data
	var count int
	err = DB.QueryRow("SELECT COUNT(*) FROM videos").Scan(&count)
	if err == nil && count == 0 {
		seedVideos()
	}

	return nil
}

func seedVideos() {
	videos := []struct {
		ID    string
		Title string
		Size  string
	}{
		{"yt_1", "Flutter Tutorial - State Management", "345 MB"},
		{"yt_2", "Lofi Hip Hop Radio 24/7", "1.2 GB"},
		{"yt_3", "Tech News Weekly", "128 MB"},
	}

	for _, v := range videos {
		_, err := DB.Exec("INSERT INTO videos (id, title, size) VALUES (?, ?, ?)",
			v.ID, v.Title, v.Size)
		if err != nil {
			log.Printf("Failed to seed video: %v", err)
		}
	}
}
