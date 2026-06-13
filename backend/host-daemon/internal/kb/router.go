package kb

import (
	"encoding/json"
	"net/http"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/kb/topics", HandleGetTopics)
	mux.HandleFunc("/api/v1/kb/topics/study", HandleToggleStudy)
	mux.HandleFunc("/api/v1/kb/export-flashcards", HandleExportFlashcards)
	mux.HandleFunc("/api/v1/kb/search", HandleSearch)
}

func HandleGetTopics(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode([]map[string]interface{}{
		{"id": "t1", "title": "Calculus I", "category": "SCIENCE", "status": "LEARNING"},
		{"id": "t2", "title": "Stoicism", "category": "PHILOSOPHY", "status": "COMPLETED"},
	})
}

func HandleToggleStudy(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "updated",
	})
}

func HandleExportFlashcards(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
	})
}

func HandleSearch(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query().Get("query")
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"query": query,
		"results": []string{},
	})
}
