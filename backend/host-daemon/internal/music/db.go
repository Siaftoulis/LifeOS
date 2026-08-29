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
		album_artist TEXT DEFAULT '',
		track_number INTEGER,
		disc_number INTEGER,
		year INTEGER,
		genre TEXT DEFAULT '',
		file_path TEXT NOT NULL DEFAULT '',
		lyrics_path TEXT DEFAULT '',
		thumbnail_url TEXT DEFAULT '',
		yt_dlp_id TEXT DEFAULT '',
		duration INTEGER NOT NULL DEFAULT 0,
		bitrate INTEGER,
		codec TEXT DEFAULT '',
		replay_gain_track REAL,
		replay_gain_album REAL,
		play_count INTEGER NOT NULL DEFAULT 0,
		last_played_at INTEGER,
		added_at INTEGER NOT NULL DEFAULT 0
	);
	
	CREATE TABLE IF NOT EXISTS liked_songs (
		id TEXT PRIMARY KEY REFERENCES music_tracks(id) ON DELETE CASCADE,
		liked_at INTEGER NOT NULL
	);
	
	CREATE TABLE IF NOT EXISTS playlists (
		id TEXT PRIMARY KEY,
		name TEXT NOT NULL,
		description TEXT DEFAULT '',
		cover_art_url TEXT DEFAULT '',
		is_smart BOOLEAN NOT NULL DEFAULT 0,
		smart_type TEXT DEFAULT '',
		smart_config TEXT DEFAULT '',
		track_count INTEGER NOT NULL DEFAULT 0,
		total_duration INTEGER NOT NULL DEFAULT 0,
		created_at INTEGER NOT NULL,
		updated_at INTEGER NOT NULL
	);
	
	CREATE TABLE IF NOT EXISTS playlist_tracks (
		id TEXT NOT NULL,
		playlist_id TEXT NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
		track_id TEXT NOT NULL REFERENCES music_tracks(id) ON DELETE CASCADE,
		position INTEGER NOT NULL,
		added_at INTEGER NOT NULL,
		PRIMARY KEY (id, playlist_id, track_id)
	);
	
	CREATE TABLE IF NOT EXISTS download_queue (
		id TEXT PRIMARY KEY,
		track_id TEXT NOT NULL REFERENCES music_tracks(id) ON DELETE CASCADE,
		url TEXT NOT NULL,
		destination_path TEXT DEFAULT '',
		status TEXT NOT NULL DEFAULT 'pending',
		priority INTEGER NOT NULL DEFAULT 0,
		retry_count INTEGER NOT NULL DEFAULT 0,
		total_bytes INTEGER,
		downloaded_bytes INTEGER NOT NULL DEFAULT 0,
		error_message TEXT DEFAULT '',
		wifi_only BOOLEAN NOT NULL DEFAULT 1,
		charging_only BOOLEAN NOT NULL DEFAULT 0,
		created_at INTEGER NOT NULL,
		started_at INTEGER,
		completed_at INTEGER
	);
	
	CREATE TABLE IF NOT EXISTS listening_history (
		id TEXT PRIMARY KEY,
		track_id TEXT NOT NULL REFERENCES music_tracks(id) ON DELETE CASCADE,
		played_at INTEGER NOT NULL,
		position_ms INTEGER NOT NULL DEFAULT 0,
		duration_ms INTEGER,
		completion_rate REAL,
		skipped BOOLEAN NOT NULL DEFAULT 0,
		source TEXT DEFAULT ''
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
