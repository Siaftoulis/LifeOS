package books

import (
	"database/sql"
	"fmt"
	"log"
	"path/filepath"

	_ "modernc.org/sqlite"
)

var DB *sql.DB

func InitDB(dataDir string) error {
	dbPath := filepath.Join(dataDir, "books.db")
	log.Printf("Initializing books database at %s", dbPath)

	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return fmt.Errorf("failed to open books db: %v", err)
	}

	DB = db

	return createTables()
}

func createTables() error {
	query := `
	CREATE TABLE IF NOT EXISTS books (
		id TEXT PRIMARY KEY,
		title TEXT NOT NULL,
		author TEXT NOT NULL,
		current_page INTEGER NOT NULL,
		total_pages INTEGER NOT NULL,
		file_path TEXT NOT NULL,
		status TEXT NOT NULL DEFAULT 'NOT_STARTED'
	);
	
	CREATE TABLE IF NOT EXISTS reading_progress (
		book_id TEXT PRIMARY KEY,
		page INTEGER NOT NULL,
		seconds INTEGER NOT NULL
	);
	
	CREATE TABLE IF NOT EXISTS book_highlights (
		id TEXT PRIMARY KEY,
		book_id TEXT NOT NULL,
		text_content TEXT NOT NULL,
		note_content TEXT NOT NULL,
		page_number INTEGER NOT NULL
	);
	`

	_, err := DB.Exec(query)
	if err != nil {
		return fmt.Errorf("failed to create books tables: %v", err)
	}

	// Migration: status column on DBs created before it existed.
	var hasStatus int
	if err := DB.QueryRow("SELECT COUNT(*) FROM pragma_table_info('books') WHERE name='status'").Scan(&hasStatus); err == nil && hasStatus == 0 {
		if _, err := DB.Exec("ALTER TABLE books ADD COLUMN status TEXT NOT NULL DEFAULT 'NOT_STARTED'"); err != nil {
			return fmt.Errorf("failed to migrate books table: %v", err)
		}
	}

	// Seed data if empty
	var count int
	err = DB.QueryRow("SELECT COUNT(*) FROM books").Scan(&count)
	if err == nil && count == 0 {
		seedBooks()
	}

	return nil
}

func seedBooks() {
	books := []Book{
		{ID: "book-1", Title: "The Pragmatic Programmer", Author: "Andrew Hunt", TotalPages: 320, FilePath: "storage/books/pragmatic.epub"},
		{ID: "book-2", Title: "Clean Code", Author: "Robert C. Martin", TotalPages: 464, FilePath: "storage/books/cleancode.epub"},
	}

	for _, b := range books {
		_, err := DB.Exec("INSERT INTO books (id, title, author, current_page, total_pages, file_path) VALUES (?, ?, ?, ?, ?, ?)",
			b.ID, b.Title, b.Author, b.CurrentPage, b.TotalPages, b.FilePath)
		if err != nil {
			log.Printf("Failed to seed book %s: %v", b.Title, err)
		}
	}
}
