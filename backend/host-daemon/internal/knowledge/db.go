package knowledge

import (
	"database/sql"
	"fmt"
	"log"
	"path/filepath"

	_ "modernc.org/sqlite"
)

var DB *sql.DB

func InitDB(dataDir string) error {
	dbPath := filepath.Join(dataDir, "knowledge.db")
	log.Printf("Initializing knowledge database at %s", dbPath)

	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return fmt.Errorf("failed to open knowledge db: %v", err)
	}

	DB = db

	return createTables()
}

func createTables() error {
	query := `
	CREATE TABLE IF NOT EXISTS categories (
		id TEXT PRIMARY KEY,
		title TEXT NOT NULL,
		icon TEXT NOT NULL,
		color TEXT NOT NULL
	);
	
	CREATE TABLE IF NOT EXISTS articles (
		id TEXT PRIMARY KEY,
		title TEXT NOT NULL,
		excerpt TEXT NOT NULL,
		date TEXT NOT NULL,
		category TEXT NOT NULL,
		color TEXT NOT NULL
	);
	`

	_, err := DB.Exec(query)
	if err != nil {
		return fmt.Errorf("failed to create knowledge tables: %v", err)
	}

	// Seed data
	var count int
	err = DB.QueryRow("SELECT COUNT(*) FROM categories").Scan(&count)
	if err == nil && count == 0 {
		seedKnowledge()
	}

	return nil
}

func seedKnowledge() {
	categories := []struct {
		ID    string
		Title string
		Icon  string
		Color string
	}{
		{"cat-1", "Philosophy", "lightbulb_outline", "0xFFE67E80"}, // Orange
		{"cat-2", "Technology", "computer", "0xFF7FBBB3"},          // Blue
		{"cat-3", "Science", "science_outlined", "0xFF83C092"},     // Aqua
		{"cat-4", "History", "account_balance", "0xFFDBBC7F"},      // Yellow
	}

	for _, c := range categories {
		_, err := DB.Exec("INSERT INTO categories (id, title, icon, color) VALUES (?, ?, ?, ?)",
			c.ID, c.Title, c.Icon, c.Color)
		if err != nil {
			log.Printf("Failed to seed category: %v", err)
		}
	}

	articles := []struct {
		ID       string
		Title    string
		Excerpt  string
		Date     string
		Category string
		Color    string
	}{
		{"art-1", "The Principles of Stoicism", "A deep dive into the core tenets of Stoic philosophy...", "Oct 12, 2023", "Philosophy", "0xFFE67E80"},
		{"art-2", "Understanding Docker Internals", "Exploring namespaces, cgroups...", "Oct 10, 2023", "Technology", "0xFF7FBBB3"},
		{"art-3", "Calculus: Limits and Continuity", "Notes on the foundational concepts...", "Oct 08, 2023", "Science", "0xFF83C092"},
		{"art-4", "The Fall of the Roman Empire", "Key events and structural flaws...", "Oct 05, 2023", "History", "0xFFDBBC7F"},
	}

	for _, a := range articles {
		_, err := DB.Exec("INSERT INTO articles (id, title, excerpt, date, category, color) VALUES (?, ?, ?, ?, ?, ?)",
			a.ID, a.Title, a.Excerpt, a.Date, a.Category, a.Color)
		if err != nil {
			log.Printf("Failed to seed article: %v", err)
		}
	}
}
