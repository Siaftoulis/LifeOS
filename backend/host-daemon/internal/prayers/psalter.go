package prayers

import (
	"embed"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"
)

//go:embed data/psalter_raw.json
var psalterFS embed.FS

type PsalmVerse struct {
	Text string `json:"text"`
}

type PsalmData struct {
	Number      int    `json:"number"`
	Title       string `json:"title"`
	Text        string `json:"text"`
	Translation string `json:"translation,omitempty"`
	VerseCount  int    `json:"verseCount"`
	Incomplete  bool   `json:"incomplete,omitempty"`
}

type KathismaData struct {
	Number int         `json:"number"`
	Title  string      `json:"title"`
	Psalms []PsalmData `json:"psalms"`
}

type PsalterData struct {
	Source     string         `json:"source"`
	License    string         `json:"license"`
	Kathismata []KathismaData `json:"kathismata"`
}

type PsalterResponse struct {
	Source      string         `json:"source"`
	License     string         `json:"license"`
	TotalPsalms int            `json:"total_psalms"`
	Kathismata  []KathismaData `json:"kathismata"`
}

type PsalmResponse struct {
	Number      int    `json:"number"`
	Title       string `json:"title"`
	Text        string `json:"text"`
	Translation string `json:"translation,omitempty"`
	VerseCount  int    `json:"verse_count"`
	Kathisma    int    `json:"kathisma"`
	Incomplete  bool   `json:"incomplete,omitempty"`
}

var psalterCache *PsalterData

func loadPsalter() (*PsalterData, error) {
	if psalterCache != nil {
		return psalterCache, nil
	}

	data, err := psalterFS.ReadFile("data/psalter_raw.json")
	if err != nil {
		return nil, fmt.Errorf("failed to read psalter data: %w", err)
	}

	var psalter PsalterData
	if err := json.Unmarshal(data, &psalter); err != nil {
		return nil, fmt.Errorf("failed to parse psalter data: %w", err)
	}

	psalterCache = &psalter
	return psalterCache, nil
}

func getKathismaForPsalm(psalmNum int) int {
	// Orthodox Kathismata divisions (Septuagint numbering)
	switch {
	case psalmNum >= 1 && psalmNum <= 8:
		return 1
	case psalmNum >= 9 && psalmNum <= 16:
		return 2
	case psalmNum >= 17 && psalmNum <= 23:
		return 3
	case psalmNum >= 24 && psalmNum <= 31:
		return 4
	case psalmNum >= 32 && psalmNum <= 36:
		return 5
	case psalmNum >= 37 && psalmNum <= 45:
		return 6
	case psalmNum >= 46 && psalmNum <= 54:
		return 7
	case psalmNum >= 55 && psalmNum <= 63:
		return 8
	case psalmNum >= 64 && psalmNum <= 69:
		return 9
	case psalmNum >= 70 && psalmNum <= 76:
		return 10
	case psalmNum >= 77 && psalmNum <= 84:
		return 11
	case psalmNum >= 85 && psalmNum <= 90:
		return 12
	case psalmNum >= 91 && psalmNum <= 100:
		return 13
	case psalmNum >= 101 && psalmNum <= 104:
		return 14
	case psalmNum >= 105 && psalmNum <= 108:
		return 15
	case psalmNum >= 109 && psalmNum <= 117:
		return 16
	case psalmNum == 118:
		return 17
	case psalmNum >= 119 && psalmNum <= 133:
		return 18
	case psalmNum >= 134 && psalmNum <= 142:
		return 19
	case psalmNum >= 143 && psalmNum <= 151:
		return 20
	default:
		return 1
	}
}

func handlePsalter(w http.ResponseWriter, r *http.Request) {
	psalter, err := loadPsalter()
	if err != nil {
		http.Error(w, `{"error":"failed to load psalter"}`, http.StatusInternalServerError)
		return
	}

	totalPsalms := 0
	for _, k := range psalter.Kathismata {
		totalPsalms += len(k.Psalms)
	}

	resp := PsalterResponse{
		Source:      psalter.Source,
		License:     psalter.License,
		TotalPsalms: totalPsalms,
		Kathismata:  psalter.Kathismata,
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(resp)
}

func handlePsalterPsalm(w http.ResponseWriter, r *http.Request) {
	psalter, err := loadPsalter()
	if err != nil {
		http.Error(w, `{"error":"failed to load psalter"}`, http.StatusInternalServerError)
		return
	}

	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		http.Error(w, `{"error":"missing id parameter"}`, http.StatusBadRequest)
		return
	}

	psalmNum, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, `{"error":"invalid psalm number"}`, http.StatusBadRequest)
		return
	}

	for _, k := range psalter.Kathismata {
		for _, p := range k.Psalms {
			if p.Number == psalmNum {
				resp := PsalmResponse{
					Number:      p.Number,
					Title:       p.Title,
					Text:        p.Text,
					Translation: p.Translation,
					VerseCount:  p.VerseCount,
					Kathisma:    k.Number,
					Incomplete:  p.Incomplete,
				}
				w.Header().Set("Content-Type", "application/json; charset=utf-8")
				json.NewEncoder(w).Encode(resp)
				return
			}
		}
	}

	http.Error(w, `{"error":"psalm not found"}`, http.StatusNotFound)
}

func handlePsalterSearch(w http.ResponseWriter, r *http.Request) {
	psalter, err := loadPsalter()
	if err != nil {
		http.Error(w, `{"error":"failed to load psalter"}`, http.StatusInternalServerError)
		return
	}

	q := strings.ToLower(strings.TrimSpace(r.URL.Query().Get("q")))
	if q == "" {
		http.Error(w, `{"error":"missing q parameter"}`, http.StatusBadRequest)
		return
	}

	type SearchResult struct {
		PsalmNumber int    `json:"psalm_number"`
		PsalmTitle  string `json:"psalm_title"`
		Kathisma    int    `json:"kathisma"`
		Snippet     string `json:"snippet"`
	}

	var results []SearchResult

	for _, k := range psalter.Kathismata {
		for _, p := range k.Psalms {
			lowerText := strings.ToLower(p.Text)
			lowerTrans := strings.ToLower(p.Translation)

			if idx := strings.Index(lowerText, q); idx != -1 {
				start := idx - 40
				if start < 0 {
					start = 0
				}
				end := idx + len(q) + 60
				if end > len(p.Text) {
					end = len(p.Text)
				}
				snippet := p.Text[start:end]
				if start > 0 {
					snippet = "..." + snippet
				}
				if end < len(p.Text) {
					snippet = snippet + "..."
				}

				results = append(results, SearchResult{
					PsalmNumber: p.Number,
					PsalmTitle:  p.Title,
					Kathisma:    k.Number,
					Snippet:     snippet,
				})
			} else if idx := strings.Index(lowerTrans, q); idx != -1 {
				start := idx - 40
				if start < 0 {
					start = 0
				}
				end := idx + len(q) + 60
				if end > len(p.Translation) {
					end = len(p.Translation)
				}
				snippet := p.Translation[start:end]
				if start > 0 {
					snippet = "..." + snippet
				}
				if end < len(p.Translation) {
					snippet = snippet + "..."
				}

				results = append(results, SearchResult{
					PsalmNumber: p.Number,
					PsalmTitle:  p.Title + " (Μετάφραση)",
					Kathisma:    k.Number,
					Snippet:     snippet,
				})
			}
		}
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"query":   q,
		"results": results,
		"count":   len(results),
	})
}

func RegisterPsalterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/prayers/psalter", handlePsalter)
	mux.HandleFunc("/api/v1/prayers/psalter/psalm", handlePsalterPsalm)
	mux.HandleFunc("/api/v1/prayers/psalter/search", handlePsalterSearch)
	mux.HandleFunc("/api/v1/prayers/psalter/service", handlePsalterAsService)
}

// handlePsalterAsService returns a single Psalm formatted as a PrayerService
// so the existing PrayerReaderScreen can display it
func handlePsalterAsService(w http.ResponseWriter, r *http.Request) {
	psalter, err := loadPsalter()
	if err != nil {
		http.Error(w, `{"error":"failed to load psalter"}`, http.StatusInternalServerError)
		return
	}

	idStr := r.URL.Query().Get("id")
	if idStr == "" {
		http.Error(w, `{"error":"missing id parameter"}`, http.StatusBadRequest)
		return
	}

	// Parse "psalm_123" format
	psalmNum := 0
	if strings.HasPrefix(idStr, "psalm_") {
		n, err := strconv.Atoi(strings.TrimPrefix(idStr, "psalm_"))
		if err != nil {
			http.Error(w, `{"error":"invalid psalm id"}`, http.StatusBadRequest)
			return
		}
		psalmNum = n
	} else {
		http.Error(w, `{"error":"invalid psalm id format"}`, http.StatusBadRequest)
		return
	}

	for _, k := range psalter.Kathismata {
		for _, p := range k.Psalms {
			if p.Number == psalmNum {
				sections := []map[string]interface{}{
					{
						"header":     p.Title,
						"content":    p.Text,
						"is_rubric":  false,
						"is_dynamic": false,
					},
				}
				if p.Translation != "" {
					sections = append(sections, map[string]interface{}{
						"header":     "Νεοελληνική Απόδοση",
						"content":    p.Translation,
						"is_rubric":  false,
						"is_dynamic": false,
					})
				}

				resp := map[string]interface{}{
					"id":            idStr,
					"title":         p.Title,
					"category":      "Ψαλτήριον",
					"subtitle":      fmt.Sprintf("Κάθισμα %d · Ψαλμός %d", k.Number, p.Number),
					"estimated_min": 5,
					"sections":      sections,
				}
				w.Header().Set("Content-Type", "application/json; charset=utf-8")
				json.NewEncoder(w).Encode(resp)
				return
			}
		}
	}

	http.Error(w, `{"error":"psalm not found"}`, http.StatusNotFound)
}
