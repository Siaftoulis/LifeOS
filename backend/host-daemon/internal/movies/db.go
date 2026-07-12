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
	ID       string `json:"id"`
	Title    string `json:"title"`
	Director string `json:"director"`
	Year     string `json:"year"`
	ColorHex string `json:"color"`
	Status   string `json:"status"`
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
		title TEXT NOT NULL,
		director TEXT NOT NULL,
		release_year TEXT NOT NULL,
		color_hex TEXT NOT NULL,
		status TEXT NOT NULL,
		created_at DATETIME NOT NULL
	);
	`

	_, err := DB.Exec(query)
	if err != nil {
		return fmt.Errorf("failed to create movies table: %v", err)
	}

	// Seed data if empty
	var count int
	err = DB.QueryRow("SELECT COUNT(*) FROM movies").Scan(&count)
	if err == nil && count == 0 {
		seedMovies()
	}

	return nil
}

func seedMovies() {
	movies := []Movie{
		{ID: "m1", Title: "Inception", Director: "Christopher Nolan", Year: "2010", ColorHex: "0xFFD3869B", Status: "AVAILABLE"},
		{ID: "m2", Title: "The Matrix", Director: "The Wachowskis", Year: "1999", ColorHex: "0xFFA9B665", Status: "AVAILABLE"},
		{ID: "m3", Title: "Interstellar", Director: "Christopher Nolan", Year: "2014", ColorHex: "0xFF7DAEA3", Status: "AVAILABLE"},
		{ID: "m4", Title: "Pulp Fiction", Director: "Quentin Tarantino", Year: "1994", ColorHex: "0xFFEA6962", Status: "AVAILABLE"},
		{ID: "m5", Title: "The Godfather", Director: "Francis Ford Coppola", Year: "1972", ColorHex: "0xFFE78A4E", Status: "AVAILABLE"},
		{ID: "m6", Title: "The Dark Knight", Director: "Christopher Nolan", Year: "2008", ColorHex: "0xFFD8A657", Status: "AVAILABLE"},
		{ID: "m7", Title: "Fight Club", Director: "David Fincher", Year: "1999", ColorHex: "0xFF89B482", Status: "AVAILABLE"},
		{ID: "m8", Title: "Forrest Gump", Director: "Robert Zemeckis", Year: "1994", ColorHex: "0xFF89B482", Status: "AVAILABLE"},
	}

	for _, m := range movies {
		_, err := DB.Exec("INSERT INTO movies (id, title, director, release_year, color_hex, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
			m.ID, m.Title, m.Director, m.Year, m.ColorHex, m.Status, time.Now())
		if err != nil {
			log.Printf("Failed to seed movie %s: %v", m.Title, err)
		}
	}
}
