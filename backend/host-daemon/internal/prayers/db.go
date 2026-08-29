package prayers

import (
	"database/sql"
	"fmt"
	"os"
	"path/filepath"
	"time"

	_ "modernc.org/sqlite"
)

var DB *sql.DB

// InitDB initializes the SQLite database for prayer bookmarks & personal rules
func InitDB(dataDir string) error {
	if err := os.MkdirAll(dataDir, 0755); err != nil {
		return err
	}

	dbPath := filepath.Join(dataDir, "prayers.db")
	var err error
	DB, err = sql.Open("sqlite", dbPath)
	if err != nil {
		return fmt.Errorf("failed to open prayers.db: %w", err)
	}

	schema := `
	CREATE TABLE IF NOT EXISTS prayer_favorites (
		id TEXT PRIMARY KEY,
		service_id TEXT NOT NULL,
		note TEXT,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

	CREATE TABLE IF NOT EXISTS prayer_logs (
		id TEXT PRIMARY KEY,
		service_id TEXT NOT NULL,
		duration_sec INTEGER,
		completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);
	`
	_, err = DB.Exec(schema)
	return err
}

// AddFavorite stores a prayer bookmark
func AddFavorite(id string, serviceID string, note string) error {
	_, err := DB.Exec(
		"INSERT OR REPLACE INTO prayer_favorites (id, service_id, note, created_at) VALUES (?, ?, ?, ?)",
		id, serviceID, note, time.Now(),
	)
	return err
}

// RemoveFavorite deletes a bookmark
func RemoveFavorite(id string) error {
	_, err := DB.Exec("DELETE FROM prayer_favorites WHERE id = ?", id)
	return err
}

// GetFavorites returns all user bookmarks
func GetFavorites() ([]FavoritePrayer, error) {
	rows, err := DB.Query("SELECT id, service_id, note, created_at FROM prayer_favorites ORDER BY created_at DESC")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []FavoritePrayer
	for rows.Next() {
		var f FavoritePrayer
		var note sql.NullString
		if err := rows.Scan(&f.ID, &f.ServiceID, &note, &f.CreatedAt); err == nil {
			if note.Valid {
				f.Note = note.String
			}
			list = append(list, f)
		}
	}
	if list == nil {
		list = []FavoritePrayer{}
	}
	return list, nil
}

// LogPrayerCompletion records a completed prayer rule
func LogPrayerCompletion(id string, username string, serviceID string, durationSec int) error {
	nowStr := time.Now().Format("2006-01-02 15:04:05")
	_, err := DB.Exec(
		"INSERT INTO prayer_logs (id, service_id, duration_sec, completed_at) VALUES (?, ?, ?, ?)",
		id, serviceID, durationSec, nowStr,
	)
	return err
}

// GetCompletedItemsForDate returns map of service_id to completion timestamp for a specific date
func GetCompletedItemsForDate(dateStr string) (map[string]string, error) {
	query := "SELECT service_id, completed_at FROM prayer_logs WHERE substr(completed_at, 1, 10) = ?"
	rows, err := DB.Query(query, dateStr)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	completed := make(map[string]string)
	for rows.Next() {
		var sID string
		var cAt string
		if err := rows.Scan(&sID, &cAt); err == nil {
			completed[sID] = cAt
		}
	}
	return completed, nil
}

// GetPrayerStreak calculates consecutive daily prayer streak
func GetPrayerStreak() int {
	query := "SELECT DISTINCT substr(completed_at, 1, 10) as log_date FROM prayer_logs ORDER BY log_date DESC LIMIT 365"
	rows, err := DB.Query(query)
	if err != nil {
		return 0
	}
	defer rows.Close()

	var dates []string
	for rows.Next() {
		var d string
		if err := rows.Scan(&d); err == nil && d != "" {
			dates = append(dates, d)
		}
	}

	if len(dates) == 0 {
		return 0
	}

	today := time.Now().Format("2006-01-02")
	yesterday := time.Now().AddDate(0, 0, -1).Format("2006-01-02")

	// If no prayer today and no prayer yesterday, streak is 0
	if dates[0] != today && dates[0] != yesterday {
		return 0
	}

	streak := 0
	checkDate := time.Now()
	if dates[0] == yesterday {
		checkDate = time.Now().AddDate(0, 0, -1)
	}

	dateSet := make(map[string]bool)
	for _, d := range dates {
		dateSet[d] = true
	}

	for {
		dStr := checkDate.Format("2006-01-02")
		if dateSet[dStr] {
			streak++
			checkDate = checkDate.AddDate(0, 0, -1)
		} else {
			break
		}
	}

	return streak
}
