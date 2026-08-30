package prayers

import (
	"embed"
	"encoding/json"
	"fmt"
	"net/http"
)

//go:embed data/lectionary_raw.json
var lectionaryFS embed.FS

type LectionaryReading struct {
	Reference    string `json:"reference"`
	ReferenceRaw string `json:"reference_raw"`
	Text         string `json:"text"`
}

type LectionaryDay struct {
	Epistle LectionaryReading `json:"epistle"`
	Gospel  LectionaryReading `json:"gospel"`
	Feast   string            `json:"feast"`
}

type LectionaryData struct {
	Source   string                     `json:"source"`
	Year     int                        `json:"year"`
	Readings map[string]LectionaryDay   `json:"readings"`
}

var lectionaryCache *LectionaryData

func loadLectionary() (*LectionaryData, error) {
	if lectionaryCache != nil {
		return lectionaryCache, nil
	}

	data, err := lectionaryFS.ReadFile("data/lectionary_raw.json")
	if err != nil {
		return nil, fmt.Errorf("failed to read lectionary data: %w", err)
	}

	var lectionary LectionaryData
	if err := json.Unmarshal(data, &lectionary); err != nil {
		return nil, fmt.Errorf("failed to parse lectionary data: %w", err)
	}

	lectionaryCache = &lectionary
	return lectionaryCache, nil
}

func RegisterLectionaryRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/prayers/lectionary", handleLectionaryDay)
	mux.HandleFunc("/api/v1/prayers/lectionary/month", handleLectionaryMonth)
}

func handleLectionaryDay(w http.ResponseWriter, r *http.Request) {
	lectionary, err := loadLectionary()
	if err != nil {
		http.Error(w, `{"error":"failed to load lectionary"}`, http.StatusInternalServerError)
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
		dateKey = q[len(q)-5:]
	}

	day, exists := lectionary.Readings[dateKey]
	if !exists {
		// Return empty readings for days without data (e.g. Great Lent weekdays)
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(map[string]interface{}{
			"date":     dateKey,
			"feast":    "",
			"epistle":  nil,
			"gospel":   nil,
			"has_readings": false,
		})
		return
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"date":     dateKey,
		"feast":    day.Feast,
		"epistle":  day.Epistle,
		"gospel":   day.Gospel,
		"has_readings": day.Epistle.Reference != "" || day.Gospel.Reference != "",
	})
}

func handleLectionaryMonth(w http.ResponseWriter, r *http.Request) {
	lectionary, err := loadLectionary()
	if err != nil {
		http.Error(w, `{"error":"failed to load lectionary"}`, http.StatusInternalServerError)
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
		Date        string `json:"date"`
		Feast       string `json:"feast"`
		EpistleRef  string `json:"epistle_ref"`
		GospelRef   string `json:"gospel_ref"`
		HasReadings bool   `json:"has_readings"`
	}

	var days []MonthDay
	daysInMonth := []int{31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
	maxDay := daysInMonth[month-1]

	for day := 1; day <= maxDay; day++ {
		dateKey := fmt.Sprintf("%02d-%02d", month, day)
		d, exists := lectionary.Readings[dateKey]

		epistleRef := ""
		gospelRef := ""
		feast := ""
		hasReadings := false

		if exists {
			epistleRef = d.Epistle.Reference
			gospelRef = d.Gospel.Reference
			feast = d.Feast
			hasReadings = epistleRef != "" || gospelRef != ""
		}

		days = append(days, MonthDay{
			Date:        dateKey,
			Feast:       feast,
			EpistleRef:  epistleRef,
			GospelRef:   gospelRef,
			HasReadings: hasReadings,
		})
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"month":      month,
		"month_name": monthNameGR[month],
		"days":       days,
	})
}
