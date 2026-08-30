package prayers

import (
	"embed"
	"encoding/json"
	"fmt"
	"net/http"
)

//go:embed data/sacraments_raw.json
var sacramentsFS embed.FS

type SacramentService struct {
	ID            string `json:"id"`
	Title         string `json:"title"`
	SectionsCount int    `json:"sections_count"`
}

type SacramentsBook struct {
	Title    string             `json:"title"`
	Services []SacramentService `json:"services"`
}

var sacramentsCache *SacramentsBook

func loadSacraments() (*SacramentsBook, error) {
	if sacramentsCache != nil {
		return sacramentsCache, nil
	}
	data, err := sacramentsFS.ReadFile("data/sacraments_raw.json")
	if err != nil {
		return nil, fmt.Errorf("failed to read sacraments: %w", err)
	}
	var book SacramentsBook
	if err := json.Unmarshal(data, &book); err != nil {
		return nil, fmt.Errorf("failed to parse sacraments: %w", err)
	}
	sacramentsCache = &book
	return sacramentsCache, nil
}

func RegisterSacramentsRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/prayers/sacraments", handleSacraments)
	mux.HandleFunc("/api/v1/prayers/sacraments/service", handleSacramentsService)
}

func handleSacraments(w http.ResponseWriter, r *http.Request) {
	book, err := loadSacraments()
	if err != nil {
		http.Error(w, `{"error":"failed to load sacraments"}`, http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(book)
}

func handleSacramentsService(w http.ResponseWriter, r *http.Request) {
	book, err := loadSacraments()
	if err != nil {
		http.Error(w, `{"error":"failed to load sacraments"}`, http.StatusInternalServerError)
		return
	}
	id := r.URL.Query().Get("id")
	if id == "" {
		http.Error(w, `{"error":"missing id parameter"}`, http.StatusBadRequest)
		return
	}
	for _, s := range book.Services {
		if s.ID == id {
			w.Header().Set("Content-Type", "application/json; charset=utf-8")
			json.NewEncoder(w).Encode(s)
			return
		}
	}
	http.Error(w, `{"error":"service not found"}`, http.StatusNotFound)
}
