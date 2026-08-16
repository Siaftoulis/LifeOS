package engine

import (
	"crypto/rand"
	"encoding/json"
	"fmt"
	"net/http"

	"lifeos/host-daemon/internal/bus"
)

func generateID() string {
	b := make([]byte, 16)
	rand.Read(b)
	return fmt.Sprintf("%x", b)
}

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/engine/entities", handleEntities)
}

func handleEntities(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		userID := r.Header.Get("X-User-ID")
		if userID == "" {
			userID = "system" // Default fallback for development
		}

		entities := GetEntitiesByUser(userID)
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(entities)

	case http.MethodPost:
		var entity Entity
		if err := json.NewDecoder(r.Body).Decode(&entity); err != nil {
			http.Error(w, "Bad Request", http.StatusBadRequest)
			return
		}

		if entity.ID == "" {
			entity.ID = generateID()
		}

		SaveEntity(entity)
		// The engine only announces; every rule lives in internal/automations.
		bus.Publish(bus.Event{
			Topic:   "engine:upsert:" + string(entity.Type),
			UserID:  entity.CreatorID,
			Payload: entity,
		})

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(entity)

	default:
		http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
	}
}
