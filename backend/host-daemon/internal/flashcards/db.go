package flashcards

import (
	"database/sql"
	"fmt"
	"log"
	"path/filepath"

	_ "modernc.org/sqlite"
)

var DB *sql.DB

func InitDB(dataDir string) error {
	dbPath := filepath.Join(dataDir, "flashcards.db")
	log.Printf("Initializing flashcards database at %s", dbPath)

	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return fmt.Errorf("failed to open flashcards db: %v", err)
	}

	DB = db

	return createTables()
}

func createTables() error {
	query := `
	CREATE TABLE IF NOT EXISTS decks (
		id TEXT PRIMARY KEY,
		name TEXT NOT NULL,
		new_cards INTEGER NOT NULL,
		due_cards INTEGER NOT NULL
	);
	`

	_, err := DB.Exec(query)
	if err != nil {
		return fmt.Errorf("failed to create flashcards tables: %v", err)
	}

	// Seed data
	var count int
	err = DB.QueryRow("SELECT COUNT(*) FROM decks").Scan(&count)
	if err == nil && count == 0 {
		seedDecks()
	}

	return nil
}

func seedDecks() {
	decks := []struct {
		ID       string
		Name     string
		NewCards int
		DueCards int
	}{
		{"d1", "Go Programming", 12, 45},
		{"d2", "Spanish Vocabulary", 20, 10},
		{"d3", "World History", 5, 2},
	}

	for _, d := range decks {
		_, err := DB.Exec("INSERT INTO decks (id, name, new_cards, due_cards) VALUES (?, ?, ?, ?)",
			d.ID, d.Name, d.NewCards, d.DueCards)
		if err != nil {
			log.Printf("Failed to seed deck: %v", err)
		}
	}
}
