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
		album TEXT NOT NULL,
		file_path TEXT NOT NULL DEFAULT ''
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

	// Migration: file_path column on DBs created before it existed (the
	// stream handler already queries it).
	var hasPath int
	if err := DB.QueryRow("SELECT COUNT(*) FROM pragma_table_info('music_tracks') WHERE name='file_path'").Scan(&hasPath); err == nil && hasPath == 0 {
		if _, err := DB.Exec("ALTER TABLE music_tracks ADD COLUMN file_path TEXT NOT NULL DEFAULT ''"); err != nil {
			return fmt.Errorf("failed to migrate music_tracks table: %v", err)
		}
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
		ID       string
		Title    string
		Artist   string
		Album    string
		FilePath string
	}{
		{"t1", "Nightcall", "Kavinsky", "OutRun", "storage/media/nightcall.mp3"},
		{"t2", "Resonance", "HOME", "Odyssey", "storage/media/resonance.mp3"},
		{"t3", "Blinding Lights", "The Weeknd", "After Hours", "storage/media/blinding_lights.mp3"},
	}

	for _, t := range tracks {
		_, err := DB.Exec("INSERT INTO music_tracks (id, title, artist, album, file_path) VALUES (?, ?, ?, ?, ?)",
			t.ID, t.Title, t.Artist, t.Album, t.FilePath)
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
