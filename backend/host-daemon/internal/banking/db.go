package banking

import (
	"database/sql"
	"fmt"
	"log"
	"path/filepath"

	_ "modernc.org/sqlite"
)

var DB *sql.DB

func InitDB(dataDir string) error {
	dbPath := filepath.Join(dataDir, "finance.db")
	log.Printf("Initializing finance database at %s", dbPath)

	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return fmt.Errorf("failed to open finance db: %v", err)
	}

	DB = db

	return createTables()
}

func createTables() error {
	query := `
	CREATE TABLE IF NOT EXISTS accounts (
		id TEXT PRIMARY KEY,
		name TEXT NOT NULL,
		balance REAL NOT NULL
	);
	
	CREATE TABLE IF NOT EXISTS transactions (
		id TEXT PRIMARY KEY,
		title TEXT NOT NULL,
		amount REAL NOT NULL,
		category TEXT NOT NULL,
		date TEXT NOT NULL,
		type TEXT NOT NULL
	);
	`

	_, err := DB.Exec(query)
	if err != nil {
		return fmt.Errorf("failed to create finance tables: %v", err)
	}

	// Seed data
	var count int
	err = DB.QueryRow("SELECT COUNT(*) FROM transactions").Scan(&count)
	if err == nil && count == 0 {
		seedFinance()
	}

	return nil
}

func seedFinance() {
	_, err := DB.Exec("INSERT INTO accounts (id, name, balance) VALUES ('acc-1', 'Main Checking', 12450.80)")
	if err != nil {
		log.Printf("Failed to seed account: %v", err)
	}

	transactions := []struct {
		ID       string
		Title    string
		Amount   float64
		Category string
		Date     string
		Type     string
	}{
		{"tx-1", "Whole Foods Market", -145.20, "Groceries", "Today, 10:45 AM", "expense"},
		{"tx-2", "Netflix Subscription", -15.99, "Entertainment", "Yesterday", "expense"},
		{"tx-3", "Salary Deposit", 4200.00, "Income", "Oct 20, 2026", "income"},
		{"tx-4", "Electric Bill", -85.00, "Utilities", "Oct 18, 2026", "expense"},
	}

	for _, tx := range transactions {
		_, err := DB.Exec("INSERT INTO transactions (id, title, amount, category, date, type) VALUES (?, ?, ?, ?, ?, ?)",
			tx.ID, tx.Title, tx.Amount, tx.Category, tx.Date, tx.Type)
		if err != nil {
			log.Printf("Failed to seed transaction: %v", err)
		}
	}
}
