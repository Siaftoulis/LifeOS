package prayers

import (
	"embed"
	"encoding/json"
	"fmt"
	"net/http"
)

//go:embed data/horologion_raw.json
var horologionFS embed.FS

//go:embed data/horologion_expanded_raw.json
var horologionExpandedFS embed.FS

type HorologionSection struct {
	Header    string `json:"header"`
	Content   string `json:"content"`
	IsRubric  bool   `json:"is_rubric"`
	IsDynamic bool   `json:"is_dynamic"`
}

type HorologionService struct {
	ID         string               `json:"id"`
	Title      string               `json:"title"`
	TitleTrans string               `json:"title_transliterated"`
	Category   string               `json:"category"`
	Sections   []HorologionSection `json:"sections"`
}

type HorologionData struct {
	Meta     map[string]interface{} `json:"meta"`
	Services []HorologionService    `json:"services"`
}

var horologionCache *HorologionData

func loadHorologion() (*HorologionData, error) {
	if horologionCache != nil {
		return horologionCache, nil
	}

	// Load base horologion
	data, err := horologionFS.ReadFile("data/horologion_raw.json")
	if err != nil {
		return nil, fmt.Errorf("failed to read horologion data: %w", err)
	}
	var horologion HorologionData
	if err := json.Unmarshal(data, &horologion); err != nil {
		return nil, fmt.Errorf("failed to parse horologion data: %w", err)
	}

	// Load expanded horologion and merge
	expandedData, err := horologionExpandedFS.ReadFile("data/horologion_expanded_raw.json")
	if err == nil {
		var expanded struct {
			Services []HorologionService `json:"services"`
		}
		if err := json.Unmarshal(expandedData, &expanded); err == nil {
			// Add expanded services that don't exist in base
			existing := make(map[string]bool)
			for _, svc := range horologion.Services {
				existing[svc.ID] = true
			}
			for _, svc := range expanded.Services {
				if !existing[svc.ID] {
					horologion.Services = append(horologion.Services, svc)
				}
			}
		}
	}

	horologionCache = &horologion
	return horologionCache, nil
}

func RegisterHorologionRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/prayers/horologion", handleHorologionList)
	mux.HandleFunc("/api/v1/prayers/horologion/service", handleHorologionService)
}

func handleHorologionList(w http.ResponseWriter, r *http.Request) {
	horologion, err := loadHorologion()
	if err != nil {
		http.Error(w, `{"error":"failed to load horologion"}`, http.StatusInternalServerError)
		return
	}

	type ServiceSummary struct {
		ID           string `json:"id"`
		Title        string `json:"title"`
		TitleTrans   string `json:"title_transliterated"`
		Category     string `json:"category"`
		SectionCount int    `json:"section_count"`
	}

	summaries := make([]ServiceSummary, len(horologion.Services))
	for i, svc := range horologion.Services {
		summaries[i] = ServiceSummary{
			ID:           svc.ID,
			Title:        svc.Title,
			TitleTrans:   svc.TitleTrans,
			Category:     svc.Category,
			SectionCount: len(svc.Sections),
		}
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"services": summaries,
		"count":    len(summaries),
	})
}

func handleHorologionService(w http.ResponseWriter, r *http.Request) {
	horologion, err := loadHorologion()
	if err != nil {
		http.Error(w, `{"error":"failed to load horologion"}`, http.StatusInternalServerError)
		return
	}

	id := r.URL.Query().Get("id")
	if id == "" {
		http.Error(w, `{"error":"missing id parameter"}`, http.StatusBadRequest)
		return
	}

	for _, svc := range horologion.Services {
		if svc.ID == id {
			w.Header().Set("Content-Type", "application/json; charset=utf-8")
			json.NewEncoder(w).Encode(svc)
			return
		}
	}

	http.Error(w, fmt.Sprintf(`{"error":"service '%s' not found"}`, id), http.StatusNotFound)
}
