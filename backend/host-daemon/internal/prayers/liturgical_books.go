package prayers

import (
	"embed"
	"encoding/json"
	"fmt"
	"net/http"
)

//go:embed data/triodion_raw.json
var triodionFS embed.FS

//go:embed data/pentecostarion_raw.json
var pentecostarionFS embed.FS

type LiturgicalBook struct {
	Title    string           `json:"title"`
	Services []PrayerService  `json:"services"`
}

var triodionCache *LiturgicalBook
var pentecostarionCache *LiturgicalBook

func loadTriodion() (*LiturgicalBook, error) {
	if triodionCache != nil {
		return triodionCache, nil
	}
	data, err := triodionFS.ReadFile("data/triodion_raw.json")
	if err != nil {
		return nil, fmt.Errorf("failed to read triodion: %w", err)
	}
	var book LiturgicalBook
	if err := json.Unmarshal(data, &book); err != nil {
		return nil, fmt.Errorf("failed to parse triodion: %w", err)
	}
	triodionCache = &book
	return triodionCache, nil
}

func loadPentecostarion() (*LiturgicalBook, error) {
	if pentecostarionCache != nil {
		return pentecostarionCache, nil
	}
	data, err := pentecostarionFS.ReadFile("data/pentecostarion_raw.json")
	if err != nil {
		return nil, fmt.Errorf("failed to read pentecostarion: %w", err)
	}
	var book LiturgicalBook
	if err := json.Unmarshal(data, &book); err != nil {
		return nil, fmt.Errorf("failed to parse pentecostarion: %w", err)
	}
	pentecostarionCache = &book
	return pentecostarionCache, nil
}

func RegisterLiturgicalBookRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/prayers/triodion", handleTriodion)
	mux.HandleFunc("/api/v1/prayers/triodion/service", handleTriodionService)
	mux.HandleFunc("/api/v1/prayers/pentecostarion", handlePentecostarion)
	mux.HandleFunc("/api/v1/prayers/pentecostarion/service", handlePentecostarionService)
}

func handleTriodion(w http.ResponseWriter, r *http.Request) {
	book, err := loadTriodion()
	if err != nil {
		http.Error(w, `{"error":"failed to load triodion"}`, http.StatusInternalServerError)
		return
	}
	type ServiceSummary struct {
		ID           string `json:"id"`
		Title        string `json:"title"`
		SectionsCount int   `json:"sections_count"`
	}
	var summaries []ServiceSummary
	for _, s := range book.Services {
		summaries = append(summaries, ServiceSummary{
			ID:            s.ID,
			Title:         s.Title,
			SectionsCount: len(s.Sections),
		})
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"title":    book.Title,
		"services": summaries,
	})
}

func handleTriodionService(w http.ResponseWriter, r *http.Request) {
	book, err := loadTriodion()
	if err != nil {
		http.Error(w, `{"error":"failed to load triodion"}`, http.StatusInternalServerError)
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

func handlePentecostarion(w http.ResponseWriter, r *http.Request) {
	book, err := loadPentecostarion()
	if err != nil {
		http.Error(w, `{"error":"failed to load pentecostarion"}`, http.StatusInternalServerError)
		return
	}
	type ServiceSummary struct {
		ID           string `json:"id"`
		Title        string `json:"title"`
		SectionsCount int   `json:"sections_count"`
	}
	var summaries []ServiceSummary
	for _, s := range book.Services {
		summaries = append(summaries, ServiceSummary{
			ID:            s.ID,
			Title:         s.Title,
			SectionsCount: len(s.Sections),
		})
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"title":    book.Title,
		"services": summaries,
	})
}

func handlePentecostarionService(w http.ResponseWriter, r *http.Request) {
	book, err := loadPentecostarion()
	if err != nil {
		http.Error(w, `{"error":"failed to load pentecostarion"}`, http.StatusInternalServerError)
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
