package voice

import (
	"encoding/json"
	"net/http"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/voice-parse", HandleVoiceParse)
}

func HandleVoiceParse(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	
	var req map[string]string
	if err := json.NewDecoder(r.Body).Decode(&req); err == nil {
		if text := req["text"]; text != "" {
			DB.Exec("INSERT INTO transcripts (text, timestamp) VALUES (?, strftime('%s', 'now'))", text)
		}
	}

	response := map[string]interface{}{
		"title":    "Clean room",
		"due_date": 1780000000000,
		"priority": 2,
		"category": "Home",
	}

	json.NewEncoder(w).Encode(response)
}
