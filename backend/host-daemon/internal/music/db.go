package music

import (
	"database/sql"
	"fmt"
	"log"
	"path/filepath"

	_ "modernc.org/sqlite"
)

var DB *sql.DB
var DataDir string

func InitDB(dataDir string) error {
	DataDir = dataDir
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
		file_path TEXT NOT NULL DEFAULT '',
		duration REAL NOT NULL DEFAULT 0,
		thumbnail TEXT NOT NULL DEFAULT ''
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

	// Migrations for DBs created before these columns existed.
	for _, col := range []struct{ name, ddl string }{
		{"file_path", "ALTER TABLE music_tracks ADD COLUMN file_path TEXT NOT NULL DEFAULT ''"},
		{"duration", "ALTER TABLE music_tracks ADD COLUMN duration REAL NOT NULL DEFAULT 0"},
		{"thumbnail", "ALTER TABLE music_tracks ADD COLUMN thumbnail TEXT NOT NULL DEFAULT ''"},
	} {
		var has int
		if err := DB.QueryRow("SELECT COUNT(*) FROM pragma_table_info('music_tracks') WHERE name=?", col.name).Scan(&has); err == nil && has == 0 {
			if _, err := DB.Exec(col.ddl); err != nil {
				return fmt.Errorf("failed to migrate music_tracks (%s): %v", col.name, err)
			}
		}
	}

	// Remove legacy placeholder records if any exist
	DB.Exec("DELETE FROM music_tracks WHERE file_path LIKE 'storage/media/%' OR id IN ('t1', 't2', 't3')")

	return nil
}

func seedMedia() {
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
		_, err := DB.Exec("INSERT OR IGNORE INTO photos (id, title, url, date) VALUES (?, ?, ?, ?)",
			p.ID, p.Title, p.URL, p.Date)
		if err != nil {
			log.Printf("Failed to seed photo: %v", err)
		}
	}
}
