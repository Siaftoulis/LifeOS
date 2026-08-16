package engine

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"path/filepath"
	"sync"
	"time"

	_ "modernc.org/sqlite"
)

var (
	storeMutex sync.RWMutex
	entitiesDB = make(map[string]Entity)
	db         *sql.DB
)

// InitDB opens (or creates) the engine database and loads all entities into
// memory. The map stays the read path; every write goes to both so the hub
// survives daemon restarts.
func InitDB(dataDir string) error {
	d, err := sql.Open("sqlite", filepath.Join(dataDir, "engine.db"))
	if err != nil {
		return fmt.Errorf("engine db open: %w", err)
	}
	if _, err := d.Exec(`CREATE TABLE IF NOT EXISTS entities (
		id TEXT PRIMARY KEY,
		type TEXT NOT NULL,
		creator_id TEXT NOT NULL DEFAULT '',
		payload TEXT NOT NULL DEFAULT '{}',
		shared_with TEXT NOT NULL DEFAULT '[]',
		assigned_to TEXT NOT NULL DEFAULT '',
		created_at TEXT NOT NULL,
		updated_at TEXT NOT NULL
	)`); err != nil {
		return fmt.Errorf("engine db init: %w", err)
	}
	db = d

	rows, err := db.Query("SELECT id, type, creator_id, payload, shared_with, assigned_to, created_at, updated_at FROM entities")
	if err != nil {
		return fmt.Errorf("engine db load: %w", err)
	}
	defer rows.Close()

	storeMutex.Lock()
	defer storeMutex.Unlock()
	for rows.Next() {
		var id, typ, creatorID, payload, shared, assigned, created, updated string
		if err := rows.Scan(&id, &typ, &creatorID, &payload, &shared, &assigned, &created, &updated); err != nil {
			return fmt.Errorf("engine db scan: %w", err)
		}
		var payloadMap map[string]interface{}
		var sharedList []string
		json.Unmarshal([]byte(payload), &payloadMap)
		json.Unmarshal([]byte(shared), &sharedList)
		createdAt, _ := time.Parse(time.RFC3339, created)
		updatedAt, _ := time.Parse(time.RFC3339, updated)
		entitiesDB[id] = Entity{
			ID:         id,
			Type:       EntityType(typ),
			CreatorID:  creatorID,
			Payload:    payloadMap,
			SharedWith: sharedList,
			AssignedTo: assigned,
			CreatedAt:  createdAt,
			UpdatedAt:  updatedAt,
		}
	}
	return nil
}

// SaveEntity stores or updates an entity thread-safely
func SaveEntity(e Entity) {
	storeMutex.Lock()
	defer storeMutex.Unlock()
	entitiesDB[e.ID] = e
	if db == nil {
		return
	}

	payload, _ := json.Marshal(e.Payload)
	shared, _ := json.Marshal(e.SharedWith)
	_, err := db.Exec(`INSERT INTO entities (id, type, creator_id, payload, shared_with, assigned_to, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(id) DO UPDATE SET
			type = excluded.type,
			creator_id = excluded.creator_id,
			payload = excluded.payload,
			shared_with = excluded.shared_with,
			assigned_to = excluded.assigned_to,
			updated_at = excluded.updated_at`,
		e.ID, string(e.Type), e.CreatorID, string(payload), string(shared), e.AssignedTo,
		e.CreatedAt.Format(time.RFC3339), e.UpdatedAt.Format(time.RFC3339))
	if err != nil {
		// ponytail: log and keep the in-memory copy; the UI still works for the
		// session, the write is retried on the next upsert.
		fmt.Printf("engine db write error: %v\n", err)
	}
}

// GetEntitiesByUser returns entities visible to the specified user ID (or all if system/admin)
func GetEntitiesByUser(userID string) []Entity {
	storeMutex.RLock()
	defer storeMutex.RUnlock()

	var result []Entity
	for _, e := range entitiesDB {
		// System / dev fallback sees everything
		if userID == "" || userID == "system" || userID == "panospds" {
			result = append(result, e)
			continue
		}

		if e.CreatorID == userID || e.AssignedTo == userID {
			result = append(result, e)
			continue
		}

		for _, sharedUser := range e.SharedWith {
			if sharedUser == userID {
				result = append(result, e)
				break
			}
		}
	}
	return result
}
