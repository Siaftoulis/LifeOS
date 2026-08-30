package prayers

import (
	"embed"
	"encoding/json"
	"fmt"
	"net/http"
)

//go:embed data/menaion_raw.json
var menaionFS embed.FS

type MenaionBook struct {
	Title   string          `json:"title"`
	Feasts  []PrayerService `json:"feasts"`
}

var menaionCache *MenaionBook

func loadMenaion() (*MenaionBook, error) {
	if menaionCache != nil {
		return menaionCache, nil
	}
	data, err := menaionFS.ReadFile("data/menaion_raw.json")
	if err != nil {
		return nil, fmt.Errorf("failed to read menaion: %w", err)
	}
	var book MenaionBook
	if err := json.Unmarshal(data, &book); err != nil {
		return nil, fmt.Errorf("failed to parse menaion: %w", err)
	}
	menaionCache = &book
	return menaionCache, nil
}

func RegisterMenaionRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/prayers/menaion", handleMenaion)
	mux.HandleFunc("/api/v1/prayers/menaion/service", handleMenaionService)
}

func handleMenaion(w http.ResponseWriter, r *http.Request) {
	book, err := loadMenaion()
	if err != nil {
		http.Error(w, `{"error":"failed to load menaion"}`, http.StatusInternalServerError)
		return
	}
	type FeastSummary struct {
		ID           string `json:"id"`
		Date         string `json:"date"`
		Title        string `json:"title"`
		SectionsCount int   `json:"sections_count"`
	}
	var summaries []FeastSummary
	for _, s := range book.Feasts {
		date := ""
		for _, sec := range s.Sections {
			if sec.Header == "Επιστολή" || sec.Header == "Ευαγγέλιον" {
				continue
			}
			if len(sec.Content) > 5 {
				date = sec.Content[:5]
				break
			}
		}
		summaries = append(summaries, FeastSummary{
			ID:            s.ID,
			Date:          date,
			Title:         s.Title,
			SectionsCount: len(s.Sections),
		})
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"title":  book.Title,
		"feasts": summaries,
	})
}

func handleMenaionService(w http.ResponseWriter, r *http.Request) {
	book, err := loadMenaion()
	if err != nil {
		http.Error(w, `{"error":"failed to load menaion"}`, http.StatusInternalServerError)
		return
	}
	id := r.URL.Query().Get("id")
	if id == "" {
		http.Error(w, `{"error":"missing id parameter"}`, http.StatusBadRequest)
		return
	}
	for _, s := range book.Feasts {
		if s.ID == id {
			w.Header().Set("Content-Type", "application/json; charset=utf-8")
			json.NewEncoder(w).Encode(s)
			return
		}
	}
	http.Error(w, `{"error":"feast not found"}`, http.StatusNotFound)
}
