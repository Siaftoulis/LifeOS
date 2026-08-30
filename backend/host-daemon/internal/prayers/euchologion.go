package prayers

import (
	"embed"
	"encoding/json"
	"fmt"
	"net/http"
)

//go:embed data/euchologion_raw.json
var euchologionFS embed.FS

type EuchologionBook struct {
	Title   string            `json:"title"`
	Prayers []EuchologionPrayer `json:"prayers"`
}

type EuchologionPrayer struct {
	ID       string           `json:"id"`
	Title    string           `json:"title"`
	Category string           `json:"category"`
	Sections []PrayerSection  `json:"sections"`
}

var euchologionCache *EuchologionBook

func loadEuchologion() (*EuchologionBook, error) {
	if euchologionCache != nil {
		return euchologionCache, nil
	}
	data, err := euchologionFS.ReadFile("data/euchologion_raw.json")
	if err != nil {
		return nil, fmt.Errorf("failed to read euchologion: %w", err)
	}
	var book EuchologionBook
	if err := json.Unmarshal(data, &book); err != nil {
		return nil, fmt.Errorf("failed to parse euchologion: %w", err)
	}
	euchologionCache = &book
	return euchologionCache, nil
}

func RegisterEuchologionRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/prayers/euchologion", handleEuchologion)
	mux.HandleFunc("/api/v1/prayers/euchologion/service", handleEuchologionService)
}

func handleEuchologion(w http.ResponseWriter, r *http.Request) {
	book, err := loadEuchologion()
	if err != nil {
		http.Error(w, `{"error":"failed to load euchologion"}`, http.StatusInternalServerError)
		return
	}
	type PrayerSummary struct {
		ID            string `json:"id"`
		Title         string `json:"title"`
		Category      string `json:"category"`
		SectionsCount int    `json:"sections_count"`
	}
	var summaries []PrayerSummary
	for _, p := range book.Prayers {
		summaries = append(summaries, PrayerSummary{
			ID:            p.ID,
			Title:         p.Title,
			Category:      p.Category,
			SectionsCount: len(p.Sections),
		})
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"title":   book.Title,
		"prayers": summaries,
	})
}

func handleEuchologionService(w http.ResponseWriter, r *http.Request) {
	book, err := loadEuchologion()
	if err != nil {
		http.Error(w, `{"error":"failed to load euchologion"}`, http.StatusInternalServerError)
		return
	}
	id := r.URL.Query().Get("id")
	if id == "" {
		http.Error(w, `{"error":"missing id parameter"}`, http.StatusBadRequest)
		return
	}
	for _, p := range book.Prayers {
		if p.ID == id {
			w.Header().Set("Content-Type", "application/json; charset=utf-8")
			json.NewEncoder(w).Encode(p)
			return
		}
	}
	http.Error(w, `{"error":"prayer not found"}`, http.StatusNotFound)
}
