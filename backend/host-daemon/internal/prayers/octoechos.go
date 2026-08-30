package prayers

import (
	"embed"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
)

//go:embed data/octoechos_raw.json
var octoechosFS embed.FS

type OctoechosTone struct {
	ToneNumber   string          `json:"tone_number"`
	ToneName     string          `json:"tone_name"`
	ToneNameGr   string          `json:"tone_name_greek"`
	Services     []PrayerService `json:"services"`
}

type OctoechosData struct {
	Title       string          `json:"title"`
	TitleTrans  string          `json:"title_transliterated"`
	Description string          `json:"description"`
	Tones       []OctoechosTone `json:"tones"`
}

var octoechosCache *OctoechosData

func loadOctoechos() (*OctoechosData, error) {
	if octoechosCache != nil {
		return octoechosCache, nil
	}
	data, err := octoechosFS.ReadFile("data/octoechos_raw.json")
	if err != nil {
		log.Printf("octoechos read error: %v", err)
		return nil, fmt.Errorf("failed to read octoechos: %w", err)
	}
	log.Printf("octoechos loaded %d bytes", len(data))
	var oct OctoechosData
	if err := json.Unmarshal(data, &oct); err != nil {
		log.Printf("octoechos parse error: %v", err)
		return nil, fmt.Errorf("failed to parse octoechos: %w", err)
	}
	log.Printf("octoechos parsed: %d tones", len(oct.Tones))
	octoechosCache = &oct
	return octoechosCache, nil
}

func RegisterOctoechosRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/prayers/octoechos", handleOctoechosList)
	mux.HandleFunc("/api/v1/prayers/octoechos/tone", handleOctoechosTone)
	mux.HandleFunc("/api/v1/prayers/octoechos/service", handleOctoechosService)
}

func handleOctoechosList(w http.ResponseWriter, r *http.Request) {
	oct, err := loadOctoechos()
	if err != nil {
		http.Error(w, `{"error":"failed to load octoechos"}`, http.StatusInternalServerError)
		return
	}
	type ToneSummary struct {
		ToneNumber    string `json:"tone_number"`
		ToneName      string `json:"tone_name"`
		ToneNameGr    string `json:"tone_name_greek"`
		ServiceCount  int    `json:"service_count"`
		SectionCount  int    `json:"section_count"`
	}
	var summaries []ToneSummary
	for _, t := range oct.Tones {
		secCount := 0
		for _, s := range t.Services {
			secCount += len(s.Sections)
		}
		summaries = append(summaries, ToneSummary{
			ToneNumber:   t.ToneNumber,
			ToneName:     t.ToneName,
			ToneNameGr:   t.ToneNameGr,
			ServiceCount: len(t.Services),
			SectionCount: secCount,
		})
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"title":       oct.Title,
		"description": oct.Description,
		"tones":       summaries,
	})
}

func handleOctoechosTone(w http.ResponseWriter, r *http.Request) {
	oct, err := loadOctoechos()
	if err != nil {
		http.Error(w, `{"error":"failed to load octoechos"}`, http.StatusInternalServerError)
		return
	}
	toneNum := r.URL.Query().Get("tone")
	if toneNum == "" {
		http.Error(w, `{"error":"missing tone parameter"}`, http.StatusBadRequest)
		return
	}
	for _, t := range oct.Tones {
		if t.ToneNumber == typeServiceID(toneNum) || t.ToneName == toneNum {
			type ServiceSummary struct {
				ID           string `json:"id"`
				Title        string `json:"title"`
				Category     string `json:"category"`
				SectionCount int    `json:"section_count"`
			}
			var summaries []ServiceSummary
			for _, s := range t.Services {
				summaries = append(summaries, ServiceSummary{
					ID:           s.ID,
					Title:        s.Title,
					Category:     s.Category,
					SectionCount: len(s.Sections),
				})
			}
			w.Header().Set("Content-Type", "application/json; charset=utf-8")
			json.NewEncoder(w).Encode(map[string]interface{}{
				"tone":    t,
				"services": summaries,
			})
			return
		}
	}
	http.Error(w, `{"error":"tone not found"}`, http.StatusNotFound)
}

func handleOctoechosService(w http.ResponseWriter, r *http.Request) {
	oct, err := loadOctoechos()
	if err != nil {
		http.Error(w, `{"error":"failed to load octoechos"}`, http.StatusInternalServerError)
		return
	}
	id := r.URL.Query().Get("id")
	if id == "" {
		http.Error(w, `{"error":"missing id parameter"}`, http.StatusBadRequest)
		return
	}
	for _, t := range oct.Tones {
		for _, s := range t.Services {
			if s.ID == id {
				w.Header().Set("Content-Type", "application/json; charset=utf-8")
				json.NewEncoder(w).Encode(s)
				return
			}
		}
	}
	http.Error(w, `{"error":"service not found"}`, http.StatusNotFound)
}

// typeServiceID maps tone names to service ID prefixes
func typeServiceID(tone string) string {
	return tone
}
