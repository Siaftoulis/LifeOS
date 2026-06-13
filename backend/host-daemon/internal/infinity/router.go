package infinity

import (
	"encoding/json"
	"net/http"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/infinity/daily", handleDaily)
	mux.HandleFunc("/api/v1/infinity/words", handleWords)
	mux.HandleFunc("/api/v1/infinity/trivia", handleTrivia)
}

func handleDaily(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"word": map[string]string{
			"greek": "Ενσυναίσθηση",
			"english": "Empathy",
			"definition": "The ability to understand and share the feelings of another.",
		},
		"trivia": []string{
			"Honey never spoils.",
			"A day on Venus is longer than a year on Venus.",
		},
	})
}

func handleWords(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "word_added"})
}

func handleTrivia(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "trivia_added"})
}
