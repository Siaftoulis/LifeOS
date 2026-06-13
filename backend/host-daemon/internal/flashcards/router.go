package flashcards

import (
	"encoding/json"
	"net/http"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/flashcards/decks", HandleListDecks)
	mux.HandleFunc("/api/v1/flashcards/import-anki", HandleImportAnki)
	mux.HandleFunc("/api/v1/flashcards/scan", HandleScanNotes)
}

func HandleListDecks(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode([]map[string]interface{}{
		{"name": "Go Programming", "new_cards": 12, "due_cards": 45},
	})
}

func HandleImportAnki(w http.ResponseWriter, r *http.Request) {
	// Stub: We bypass actual SQLite parsing of collection.anki2 to avoid CGO requirements on the host machine.
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "success",
		"imported_cards": 42,
		"message": "Stubbed Anki Import (No CGO required)",
	})
}

func HandleScanNotes(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "success",
		"parsed_cards": 5,
	})
}
