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
	
	// Get latest word
	var greek, english, def string
	err := DB.QueryRow("SELECT greek, english, definition FROM words ORDER BY id DESC LIMIT 1").Scan(&greek, &english, &def)
	
	wordData := map[string]string{}
	if err == nil {
		wordData = map[string]string{
			"greek":      greek,
			"english":    english,
			"definition": def,
		}
	} else {
		wordData = map[string]string{
			"greek":      "Ενσυναίσθηση",
			"english":    "Empathy",
			"definition": "The ability to understand and share the feelings of another.",
		}
	}

	// Get recent trivia
	rows, err := DB.Query("SELECT fact FROM trivia ORDER BY id DESC LIMIT 5")
	var trivias []string
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var fact string
			if err := rows.Scan(&fact); err == nil {
				trivias = append(trivias, fact)
			}
		}
	}

	if len(trivias) == 0 {
		trivias = []string{
			"Honey never spoils.",
			"A day on Venus is longer than a year on Venus.",
		}
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"word":   wordData,
		"trivia": trivias,
	})
}

func handleWords(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	
	var req map[string]string
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	_, err := DB.Exec("INSERT INTO words (greek, english, definition, date) VALUES (?, ?, ?, date('now'))",
		req["greek"], req["english"], req["definition"])
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
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

	var req map[string]string
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	_, err := DB.Exec("INSERT INTO trivia (fact, date) VALUES (?, date('now'))", req["fact"])
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "trivia_added"})
}
