package music

import (
	"database/sql"
	"fmt"
	"log"
	"path/filepath"

	_ "modernc.org/sqlite"
)

var DB *sql.DB

func InitDB(dataDir string) error {
	dbPath := filepath.Join(dataDir, "media.db")
	log.Printf("Initializing media database at %s", dbPath)

	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return fmt.Errorf("failed to open media db: %v", err)
	}

	DB = db

	return createTables()
}

func createTables() error {
	query := `
	CREATE TABLE IF NOT EXISTS music_tracks (
		id TEXT PRIMARY KEY,
		title TEXT NOT NULL,
		artist TEXT NOT NULL,
		album TEXT NOT NULL
	);
	
	CREATE TABLE IF NOT EXISTS photos (
		id TEXT PRIMARY KEY,
		title TEXT NOT NULL,
		url TEXT NOT NULL,
		date TEXT NOT NULL
	);
	`

	_, err := DB.Exec(query)
	if err != nil {
		return fmt.Errorf("failed to create media tables: %v", err)
	}

	// Seed data
	var count int
	err = DB.QueryRow("SELECT COUNT(*) FROM music_tracks").Scan(&count)
	if err == nil && count == 0 {
		seedMedia()
	}

	return nil
}

func seedMedia() {
	tracks := []struct {
		ID     string
		Title  string
		Artist string
		Album  string
	}{
		{"t1", "Nightcall", "Kavinsky", "OutRun"},
		{"t2", "Resonance", "HOME", "Odyssey"},
		{"t3", "Blinding Lights", "The Weeknd", "After Hours"},
	}

	for _, t := range tracks {
		_, err := DB.Exec("INSERT INTO music_tracks (id, title, artist, album) VALUES (?, ?, ?, ?)",
			t.ID, t.Title, t.Artist, t.Album)
		if err != nil {
			log.Printf("Failed to seed music track: %v", err)
		}
	}
	
	photos := []struct {
		ID    string
		Title string
		URL   string
		Date  string
	}{
		{"p1", "Mountain View", "https://via.placeholder.com/400x300.png?text=Mountain+View", "Oct 20, 2026"},
		{"p2", "City Skyline", "https://via.placeholder.com/400x300.png?text=City+Skyline", "Oct 18, 2026"},
		{"p3", "Forest Path", "https://via.placeholder.com/400x300.png?text=Forest+Path", "Oct 15, 2026"},
	}
	
	for _, p := range photos {
		_, err := DB.Exec("INSERT INTO photos (id, title, url, date) VALUES (?, ?, ?, ?)",
			p.ID, p.Title, p.URL, p.Date)
		if err != nil {
			log.Printf("Failed to seed photo: %v", err)
		}
	}
}
