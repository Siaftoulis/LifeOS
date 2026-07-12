package player

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"path/filepath"

	_ "modernc.org/sqlite"
)

var DB *sql.DB

func InitDB(dataDir string) error {
	dbPath := filepath.Join(dataDir, "rpg.db")
	log.Printf("Initializing RPG database at %s", dbPath)

	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return fmt.Errorf("failed to open rpg db: %v", err)
	}

	DB = db

	return createTables()
}

func createTables() error {
	query := `
	CREATE TABLE IF NOT EXISTS player (
		id TEXT PRIMARY KEY,
		xp INTEGER NOT NULL,
		age REAL NOT NULL,
		willpower REAL NOT NULL,
		attributes TEXT NOT NULL,
		last_active_at INTEGER NOT NULL
	);
	
	CREATE TABLE IF NOT EXISTS quests (
		id TEXT PRIMARY KEY,
		title TEXT NOT NULL,
		description TEXT NOT NULL,
		xp_reward INTEGER NOT NULL,
		status TEXT NOT NULL,
		assigned_users TEXT DEFAULT '',
		progress INTEGER DEFAULT 0
	);
	`
	
	_, err := DB.Exec(query)
	if err != nil {
		return fmt.Errorf("failed to create rpg tables: %v", err)
	}

	// Gracefully add columns if table already exists without them
	_, _ = DB.Exec("ALTER TABLE quests ADD COLUMN assigned_users TEXT DEFAULT ''")
	_, _ = DB.Exec("ALTER TABLE quests ADD COLUMN progress INTEGER DEFAULT 0")

	// Seed player
	var count int
	err = DB.QueryRow("SELECT COUNT(*) FROM player").Scan(&count)
	if err == nil && count == 0 {
		attrs, _ := json.Marshal(map[string]int{
			"stamina":      100,
			"intelligence": 150,
			"focus":        120,
			"charisma":     90,
			"willpower":    110,
		})
		_, err = DB.Exec("INSERT INTO player (id, xp, age, willpower, attributes, last_active_at) VALUES ('player-1', 15400, 30.0, 110.0, ?, 0)", string(attrs))
		if err != nil {
			log.Printf("Failed to seed player: %v", err)
		}
	}

	// Seed quests
	err = DB.QueryRow("SELECT COUNT(*) FROM quests").Scan(&count)
	if err == nil && count == 0 {
		_, err = DB.Exec("INSERT INTO quests (id, title, description, xp_reward, status, progress) VALUES ('q-main', 'Family Vacation', 'Gather 200 stars', 200, 'MAIN', 150)")
		_, err = DB.Exec("INSERT INTO quests (id, title, description, xp_reward, status) VALUES ('q-1', 'Drink Water', 'Drink 2 liters of water', 50, 'POOL')")
		if err != nil {
			log.Printf("Failed to seed quests: %v", err)
		}
	}

	return nil
}
