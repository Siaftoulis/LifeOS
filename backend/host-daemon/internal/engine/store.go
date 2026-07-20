package engine

import (
	"sync"
)

var (
	storeMutex sync.RWMutex
	entitiesDB = make(map[string]Entity)
)

// SaveEntity stores or updates an entity thread-safely
func SaveEntity(e Entity) {
	storeMutex.Lock()
	defer storeMutex.Unlock()
	entitiesDB[e.ID] = e
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
