package infinity

import (
	"database/sql"
	"fmt"
	"log"
	"path/filepath"

	_ "modernc.org/sqlite"
)

var DB *sql.DB

func InitDB(dataDir string) error {
	dbPath := filepath.Join(dataDir, "infinity.db")
	log.Printf("Initializing infinity database at %s", dbPath)

	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return fmt.Errorf("failed to open infinity db: %v", err)
	}

	DB = db

	return createTables()
}

func createTables() error {
	query := `
	CREATE TABLE IF NOT EXISTS words (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		greek TEXT NOT NULL,
		english TEXT NOT NULL,
		definition TEXT NOT NULL,
		date TEXT NOT NULL
	);
	
	CREATE TABLE IF NOT EXISTS trivia (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		fact TEXT NOT NULL,
		date TEXT NOT NULL
	);
	`

	_, err := DB.Exec(query)
	if err != nil {
		return fmt.Errorf("failed to create infinity tables: %v", err)
	}

	// Seed data
	var count int
	err = DB.QueryRow("SELECT COUNT(*) FROM words").Scan(&count)
	if err == nil && count == 0 {
		seedInfinity()
	}

	return nil
}

func seedInfinity() {
	_, err := DB.Exec("INSERT INTO words (greek, english, definition, date) VALUES (?, ?, ?, date('now'))",
		"Ενσυναίσθηση", "Empathy", "The ability to understand and share the feelings of another.")
	if err != nil {
		log.Printf("Failed to seed word: %v", err)
	}

	trivias := []string{
		"Honey never spoils. Archaeologists have found pots of honey in ancient Egyptian tombs that are over 3,000 years old and still perfectly edible.",
		"A day on Venus is longer than a year on Venus.",
	}

	for _, t := range trivias {
		_, err := DB.Exec("INSERT INTO trivia (fact, date) VALUES (?, date('now'))", t)
		if err != nil {
			log.Printf("Failed to seed trivia: %v", err)
		}
	}
}
