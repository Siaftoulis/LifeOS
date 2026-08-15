package movies

import (
	"database/sql"
	"fmt"
	"log"
	"path/filepath"
	"time"

	_ "modernc.org/sqlite"
)

var DB *sql.DB

type Movie struct {
	ID         string  `json:"id"`
	ImdbID     string  `json:"imdb_id"`
	Title      string  `json:"title"`
	Director   string  `json:"director"`
	Year       string  `json:"year"`
	ColorHex   string  `json:"color"`
	Status     string  `json:"status"`
	Rating     float64 `json:"rating"`
	TMDBID     int64   `json:"tmdb_id,omitempty"`
	PosterURL  string  `json:"poster_url,omitempty"`
	Overview   string  `json:"overview,omitempty"`
	Genres     string  `json:"genres,omitempty"`
	TMDBRating float64 `json:"tmdb_rating,omitempty"`
}

func InitDB(dataDir string) error {
	dbPath := filepath.Join(dataDir, "movies.db")
	log.Printf("Initializing movies database at %s", dbPath)

	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return fmt.Errorf("failed to open movies db: %v", err)
	}

	DB = db

	return createTables()
}

func createTables() error {
	query := `
	CREATE TABLE IF NOT EXISTS movies (
		id TEXT PRIMARY KEY,
		imdb_id TEXT UNIQUE,
		title TEXT NOT NULL,
		director TEXT NOT NULL,
		release_year TEXT NOT NULL,
		color_hex TEXT NOT NULL,
		status TEXT NOT NULL,
		created_at DATETIME NOT NULL
	);

	CREATE TABLE IF NOT EXISTS movie_watchlist (
		id TEXT PRIMARY KEY,
		movie_id TEXT NOT NULL,
		added_at INTEGER NOT NULL,
		priority INTEGER DEFAULT 0,
		is_dirty INTEGER DEFAULT 0,
		FOREIGN KEY(movie_id) REFERENCES movies(id) ON DELETE CASCADE
	);

	CREATE TABLE IF NOT EXISTS movie_reviews (
		id TEXT PRIMARY KEY,
		movie_id TEXT NOT NULL,
		rating REAL DEFAULT 0.0,
		comment TEXT,
		is_dirty INTEGER DEFAULT 0,
		FOREIGN KEY(movie_id) REFERENCES movies(id) ON DELETE CASCADE
	);
	`

	_, err := DB.Exec(query)
	if err != nil {
		return fmt.Errorf("failed to create movies tables: %v", err)
	}

	// Migration: add columns to DBs created before they existed.
	columns := []struct {
		name string
		ddl  string
	}{
		{"imdb_id", "ALTER TABLE movies ADD COLUMN imdb_id TEXT"},
		{"tmdb_id", "ALTER TABLE movies ADD COLUMN tmdb_id INTEGER"},
		{"poster_path", "ALTER TABLE movies ADD COLUMN poster_path TEXT"},
		{"overview", "ALTER TABLE movies ADD COLUMN overview TEXT"},
		{"genres", "ALTER TABLE movies ADD COLUMN genres TEXT"},
		{"tmdb_rating", "ALTER TABLE movies ADD COLUMN tmdb_rating REAL"},
	}
	for _, c := range columns {
		var exists int
		if err := DB.QueryRow("SELECT COUNT(*) FROM pragma_table_info('movies') WHERE name=?", c.name).Scan(&exists); err == nil && exists == 0 {
			if _, err := DB.Exec(c.ddl); err != nil {
				return fmt.Errorf("failed to migrate movies table (%s): %v", c.name, err)
			}
		}
	}
	backfillImdbIDs()

	// Seed data if empty
	var count int
	err = DB.QueryRow("SELECT COUNT(*) FROM movies").Scan(&count)
	if err == nil && count == 0 {
		seedMovies()
	}

	// Background TMDb enrichment; no-op without TMDB_API_KEY.
	go enrichAllTMDB()

	return nil
}

func backfillImdbIDs() {
	ids := map[string]string{
		"m1": "tt1375666", "m2": "tt0133093", "m3": "tt0816692", "m4": "tt0110912",
		"m5": "tt0068646", "m6": "tt0468569", "m7": "tt0137523", "m8": "tt0109830",
	}
	for id, imdb := range ids {
		DB.Exec("UPDATE movies SET imdb_id = ? WHERE id = ?", imdb, id)
	}
}

func seedMovies() {
	movies := []Movie{
		{ID: "m1", ImdbID: "tt1375666", Title: "Inception", Director: "Christopher Nolan", Year: "2010", ColorHex: "0xFFD3869B", Status: "AVAILABLE"},
		{ID: "m2", ImdbID: "tt0133093", Title: "The Matrix", Director: "The Wachowskis", Year: "1999", ColorHex: "0xFFA9B665", Status: "AVAILABLE"},
		{ID: "m3", ImdbID: "tt0816692", Title: "Interstellar", Director: "Christopher Nolan", Year: "2014", ColorHex: "0xFF7DAEA3", Status: "AVAILABLE"},
		{ID: "m4", ImdbID: "tt0110912", Title: "Pulp Fiction", Director: "Quentin Tarantino", Year: "1994", ColorHex: "0xFFEA6962", Status: "AVAILABLE"},
		{ID: "m5", ImdbID: "tt0068646", Title: "The Godfather", Director: "Francis Ford Coppola", Year: "1972", ColorHex: "0xFFE78A4E", Status: "AVAILABLE"},
		{ID: "m6", ImdbID: "tt0468569", Title: "The Dark Knight", Director: "Christopher Nolan", Year: "2008", ColorHex: "0xFFD8A657", Status: "AVAILABLE"},
		{ID: "m7", ImdbID: "tt0137523", Title: "Fight Club", Director: "David Fincher", Year: "1999", ColorHex: "0xFF89B482", Status: "AVAILABLE"},
		{ID: "m8", ImdbID: "tt0109830", Title: "Forrest Gump", Director: "Robert Zemeckis", Year: "1994", ColorHex: "0xFF89B482", Status: "AVAILABLE"},
	}

	for _, m := range movies {
		_, err := DB.Exec("INSERT OR IGNORE INTO movies (id, imdb_id, title, director, release_year, color_hex, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
			m.ID, m.ImdbID, m.Title, m.Director, m.Year, m.ColorHex, m.Status, time.Now())
		if err != nil {
			log.Printf("Failed to seed movie %s: %v", m.Title, err)
		}
	}
}
