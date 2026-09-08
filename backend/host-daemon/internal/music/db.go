package music

import (
	"database/sql"
	"fmt"
	"log"
	"path/filepath"
	"time"

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

	if err := createTables(); err != nil {
		return err
	}

	StartQueueWorker()
	return nil
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
		quality_mode TEXT NOT NULL DEFAULT 'best',
		stage TEXT NOT NULL DEFAULT 'pending',
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

	CREATE TABLE IF NOT EXISTS music_config (
		key TEXT PRIMARY KEY,
		value TEXT NOT NULL,
		updated_at INTEGER NOT NULL
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
		{"thumbnail_url", "ALTER TABLE music_tracks ADD COLUMN thumbnail_url TEXT DEFAULT ''"},
	} {
		var has int
		if err := DB.QueryRow("SELECT COUNT(*) FROM pragma_table_info('music_tracks') WHERE name=?", col.name).Scan(&has); err == nil && has == 0 {
			if _, err := DB.Exec(col.ddl); err != nil {
				return fmt.Errorf("failed to migrate music_tracks (%s): %v", col.name, err)
			}
		}
	}

	for _, col := range []struct{ name, ddl string }{
		{"quality_mode", "ALTER TABLE download_queue ADD COLUMN quality_mode TEXT NOT NULL DEFAULT 'best'"},
		{"stage", "ALTER TABLE download_queue ADD COLUMN stage TEXT NOT NULL DEFAULT 'pending'"},
	} {
		var has int
		if err := DB.QueryRow("SELECT COUNT(*) FROM pragma_table_info('download_queue') WHERE name=?", col.name).Scan(&has); err == nil && has == 0 {
			if _, err := DB.Exec(col.ddl); err != nil {
				return fmt.Errorf("failed to migrate download_queue (%s): %v", col.name, err)
			}
		}
	}

	// Bidirectional sync for existing data to ensure thumbnail consistency
	_, _ = DB.Exec(`UPDATE music_tracks SET thumbnail = thumbnail_url WHERE (thumbnail IS NULL OR thumbnail = '') AND (thumbnail_url IS NOT NULL AND thumbnail_url != '')`)
	_, _ = DB.Exec(`UPDATE music_tracks SET thumbnail_url = thumbnail WHERE (thumbnail_url IS NULL OR thumbnail_url = '') AND (thumbnail IS NOT NULL AND thumbnail != '')`)

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

// GetMusicConfig retrieves a stored configuration value from music_config.
func GetMusicConfig(key string) string {
	if DB == nil {
		return ""
	}
	var val string
	_ = DB.QueryRow("SELECT value FROM music_config WHERE key = ?", key).Scan(&val)
	return val
}

// SetMusicConfig sets or updates a configuration value in music_config.
func SetMusicConfig(key, val string) error {
	if DB == nil {
		return fmt.Errorf("media db is nil")
	}
	now := time.Now().UnixMilli()
	_, err := DB.Exec(`INSERT INTO music_config (key, value, updated_at)
		VALUES (?, ?, ?)
		ON CONFLICT(key) DO UPDATE SET value=excluded.value, updated_at=excluded.updated_at`,
		key, val, now)
	return err
}

// GetAllMusicConfig returns all stored music configuration key-values.
func GetAllMusicConfig() map[string]string {
	res := make(map[string]string)
	if DB == nil {
		return res
	}
	rows, err := DB.Query("SELECT key, value FROM music_config")
	if err != nil {
		return res
	}
	defer rows.Close()

	for rows.Next() {
		var k, v string
		if err := rows.Scan(&k, &v); err == nil {
			res[k] = v
		}
	}
	return res
}

