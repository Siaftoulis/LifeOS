package prayers

import (
	"embed"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
)

//go:embed data/synaxarion_raw.json
var synaxarionFS embed.FS

type SynaxarionSaint struct {
	Name         string `json:"name"`
	Title        string `json:"title"`
	ShortLife    string `json:"shortLife"`
	FullLife     string `json:"fullLife"`
	Apolytikion  string `json:"apolytikion"`
	Kontakion    string `json:"kontakion"`
	Megalynarion string `json:"megalynarion,omitempty"`
}

type SynaxarionDay struct {
	Feast string            `json:"feast"`
	Saints []SynaxarionSaint `json:"saints"`
}

type SynaxarionData struct {
	Source  string                     `json:"source"`
	License string                     `json:"license"`
	Days    map[string]SynaxarionDay   `json:"days"`
}

type SynaxarionResponse struct {
	Date           string            `json:"date"`
	DateFormatted  string            `json:"date_formatted"`
	Feast          string            `json:"feast"`
	Saints         []SynaxarionSaint `json:"saints"`
	SaintCount     int               `json:"saint_count"`
}

var synaxarionCache *SynaxarionData

func loadSynaxarion() (*SynaxarionData, error) {
	if synaxarionCache != nil {
		return synaxarionCache, nil
	}

	data, err := synaxarionFS.ReadFile("data/synaxarion_raw.json")
	if err != nil {
		return nil, fmt.Errorf("failed to read synaxarion data: %w", err)
	}

	var synaxarion SynaxarionData
	if err := json.Unmarshal(data, &synaxarion); err != nil {
		return nil, fmt.Errorf("failed to parse synaxarion data: %w", err)
	}

	synaxarionCache = &synaxarion
	return synaxarionCache, nil
}

// enrichWithMenologion merges rich hymn data from the hardcoded menologion
func enrichWithMenologion(dateKey string, day *SynaxarionDay) {
	if entry, exists := menologionDB[dateKey]; exists {
		// Use the richer feast name from menologion if available
		if entry.FeastName != "" && (day.Feast == "" || strings.HasPrefix(day.Feast, "Μνήμη")) {
			day.Feast = entry.FeastName
		}

		// Merge rich saint data from menologion
		for i := range day.Saints {
			for _, ms := range entry.Saints {
				// Match by partial name (e.g. "Βασίλειος" matches "Άγιος Βασίλειος ο Μέγας")
				if strings.Contains(day.Saints[i].Name, ms.Name) || strings.Contains(ms.Name, day.Saints[i].Name) {
					if ms.Title != "" {
						day.Saints[i].Title = ms.Title
					}
					if ms.ShortLife != "" {
						day.Saints[i].ShortLife = ms.ShortLife
					}
					if ms.FullLife != "" {
						day.Saints[i].FullLife = ms.FullLife
					}
					if ms.Apolytikion != "" {
						day.Saints[i].Apolytikion = ms.Apolytikion
					}
					if ms.Kontakion != "" {
						day.Saints[i].Kontakion = ms.Kontakion
					}
					if ms.Megalynarion != "" {
						day.Saints[i].Megalynarion = ms.Megalynarion
					}
				}
			}
		}
	}
}

func RegisterSynaxarionRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/prayers/synaxarion/full", handleSynaxarionFull)
	mux.HandleFunc("/api/v1/prayers/synaxarion/month", handleSynaxarionMonth)
}

func handleSynaxarionFull(w http.ResponseWriter, r *http.Request) {
	synaxarion, err := loadSynaxarion()
	if err != nil {
		http.Error(w, `{"error":"failed to load synaxarion"}`, http.StatusInternalServerError)
		return
	}

	q := r.URL.Query().Get("date")
	if q == "" {
		http.Error(w, `{"error":"missing date parameter"}`, http.StatusBadRequest)
		return
	}

	// Parse MM-DD or YYYY-MM-DD
	dateKey := q
	if len(q) > 5 {
		dateKey = q[len(q)-5:] // Extract MM-DD from YYYY-MM-DD
	}

	day := synaxarion.Days[dateKey]
	enrichWithMenologion(dateKey, &day)

	saintCount := len(day.Saints)
	if day.Saints == nil {
		day.Saints = []SynaxarionSaint{}
	}

	resp := SynaxarionResponse{
		Date:          q,
		DateFormatted: formatGreekDateFromKey(dateKey),
		Feast:         day.Feast,
		Saints:        day.Saints,
		SaintCount:    saintCount,
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(resp)
}

func handleSynaxarionMonth(w http.ResponseWriter, r *http.Request) {
	synaxarion, err := loadSynaxarion()
	if err != nil {
		http.Error(w, `{"error":"failed to load synaxarion"}`, http.StatusInternalServerError)
		return
	}

	monthStr := r.URL.Query().Get("month")
	if monthStr == "" {
		http.Error(w, `{"error":"missing month parameter"}`, http.StatusBadRequest)
		return
	}

	var month int
	if _, err := fmt.Sscanf(monthStr, "%d", &month); err != nil || month < 1 || month > 12 {
		http.Error(w, `{"error":"invalid month"}`, http.StatusBadRequest)
		return
	}

	type MonthDay struct {
		Date      string            `json:"date"`
		Feast     string            `json:"feast"`
		Saints    []SynaxarionSaint `json:"saints"`
		SaintCount int              `json:"saint_count"`
	}

	var days []MonthDay

	// Days in each month (non-leap year)
	daysInMonth := []int{31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
	maxDay := daysInMonth[month-1]

	for day := 1; day <= maxDay; day++ {
		dateKey := fmt.Sprintf("%02d-%02d", month, day)
		d := synaxarion.Days[dateKey]
		enrichWithMenologion(dateKey, &d)

		saintCount := len(d.Saints)
		if d.Saints == nil {
			d.Saints = []SynaxarionSaint{}
		}

		days = append(days, MonthDay{
			Date:       dateKey,
			Feast:      d.Feast,
			Saints:     d.Saints,
			SaintCount: saintCount,
		})
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"month":      month,
		"month_name": monthNameGR[month],
		"days":       days,
	})
}

func formatGreekDateFromKey(dateKey string) string {
	var month, day int
	fmt.Sscanf(dateKey, "%02d-%02d", &month, &day)
	weekdays := []string{"Κυριακή", "Δευτέρα", "Τρίτη", "Τετάρτη", "Πέμπτη", "Παρασκευή", "Σάββατο"}
	return fmt.Sprintf("%s, %d %s", weekdays[day%7], day, monthNameGR[month])
}

var monthNameGR = map[int]string{
	1:  "Ιανουαρίου",
	2:  "Φεβρουαρίου",
	3:  "Μαρτίου",
	4:  "Απριλίου",
	5:  "Μαΐου",
	6:  "Ιουνίου",
	7:  "Ιουλίου",
	8:  "Αυγούστου",
	9:  "Σεπτεμβρίου",
	10: "Οκτωβρίου",
	11: "Νοεμβρίου",
	12: "Δεκεμβρίου",
}
