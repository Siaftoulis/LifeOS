package prayers

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"lifeos/host-daemon/internal/auth/middleware"
	"lifeos/host-daemon/internal/points"
)

// RegisterRoutes registers all Orthodox prayers and Typikon endpoints on the mux
func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/prayers/daily", handleDailyLiturgicalInfo)
	mux.HandleFunc("/api/v1/prayers/categories", handleCategories)
	mux.HandleFunc("/api/v1/prayers/service", handlePrayerService)
	mux.HandleFunc("/api/v1/prayers/synaxarion", handleSynaxarion)
	mux.HandleFunc("/api/v1/prayers/favorites", handleFavorites)
	mux.HandleFunc("/api/v1/prayers/favorites/", handleFavoriteByID)
	mux.HandleFunc("/api/v1/prayers/rule/today", handlePrayerRuleToday)
	mux.HandleFunc("/api/v1/prayers/rule/complete", handlePrayerRuleComplete)

	// Psalter routes
	RegisterPsalterRoutes(mux)

	// Scripture routes
	RegisterScriptureRoutes(mux)

	// Synaxarion routes
	RegisterSynaxarionRoutes(mux)

	// Horologion routes
	RegisterHorologionRoutes(mux)

	// Lectionary routes
	RegisterLectionaryRoutes(mux)

	// Liturgical book routes (Triodion, Pentecostarion)
	RegisterLiturgicalBookRoutes(mux)

	// Menaion routes
	RegisterMenaionRoutes(mux)

	// Euchologion routes
	RegisterEuchologionRoutes(mux)

	// Sacraments routes
	RegisterSacramentsRoutes(mux)

	// Octoechos routes
	RegisterOctoechosRoutes(mux)

	// Canon routes
	RegisterCanonRoutes(mux)

	// Typikon dynamic routes
	mux.HandleFunc("/api/v1/prayers/typikon/today", handleTypikonToday)
	mux.HandleFunc("/api/v1/prayers/typikon/katavasies", handleTypikonKatavasies)
	mux.HandleFunc("/api/v1/prayers/typikon/variables", handleTypikonVariables)
	mux.HandleFunc("/api/v1/prayers/paraklesis/saint", handleParaklesisSaint)
}

func parseDateQuery(r *http.Request) time.Time {
	q := r.URL.Query().Get("date")
	if q != "" {
		if t, err := time.Parse("2006-01-02", q); err == nil {
			return t
		}
	}
	return time.Now()
}

func formatGreekDate(d time.Time) string {
	weekdays := []string{"Κυριακή", "Δευτέρα", "Τρίτη", "Τετάρτη", "Πέμπτη", "Παρασκευή", "Σάββατο"}
	months := []string{"", "Ιανουαρίου", "Φεβρουαρίου", "Μαρτίου", "Απριλίου", "Μαΐου", "Ιουνίου", "Ιουλίου", "Αυγούστου", "Σεπτεμβρίου", "Οκτωβρίου", "Νοεμβρίου", "Δεκεμβρίου"}

	return fmt.Sprintf("%s, %d %s %d",
		weekdays[d.Weekday()],
		d.Day(),
		months[int(d.Month())],
		d.Year(),
	)
}

func getUsername(r *http.Request) string {
	if u, ok := r.Context().Value(middleware.UserContextKey).(string); ok && u != "" {
		return u
	}
	// Try parsing token if present
	if authHeader := r.Header.Get("Authorization"); authHeader != "" {
		if claims, ok := middleware.ValidateToken(authHeader); ok && claims.Username != "" {
			return claims.Username
		}
	}
	return "panospds"
}

func handleDailyLiturgicalInfo(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	date := parseDateQuery(r)

	menologion := GetDailySaints(int(date.Month()), date.Day())
	tone := GetOctoechosTone(date)
	period, movable := GetLiturgicalPeriod(date)
	fasting := CalculateFastingRule(date)

	// Build readings from lectionary (preferred) or menologion fallback
	lectionary, _ := loadLectionary()
	dateKey := date.Format("01-02")
	lectionaryDay, hasLectionary := lectionary.Readings[dateKey]

	type ReadingRef struct {
		Reference string `json:"reference"`
		Text      string `json:"text"`
	}

	var epistleReading, gospelReading *ReadingRef
	if hasLectionary {
		if lectionaryDay.Epistle.Reference != "" {
			epistleReading = &ReadingRef{
				Reference: lectionaryDay.Epistle.Reference,
				Text:      lectionaryDay.Epistle.Text,
			}
		}
		if lectionaryDay.Gospel.Reference != "" {
			gospelReading = &ReadingRef{
				Reference: lectionaryDay.Gospel.Reference,
				Text:      lectionaryDay.Gospel.Text,
			}
		}
	} else if menologion.Apostolos.Text != "" {
		epistleReading = &ReadingRef{
			Reference: menologion.Apostolos.Reference,
			Text:      menologion.Apostolos.Text,
		}
		gospelReading = &ReadingRef{
			Reference: menologion.Evangelion.Reference,
			Text:      menologion.Evangelion.Text,
		}
	}

	katavasies := GetSeasonalKatavasies(date)

	type DailyInfo struct {
		Date          string        `json:"date"`
		DateFormatted string        `json:"date_formatted"`
		Tone          string        `json:"tone"`
		Period        string        `json:"period"`
		FeastName     string        `json:"feast_name"`
		Fasting       FastingType   `json:"fasting"`
		Saints        []Saint       `json:"saints"`
		Epistle       *ReadingRef   `json:"epistle"`
		Gospel        *ReadingRef   `json:"gospel"`
		MovableCycle  string        `json:"movable_cycle"`
		Katavasies    KatavasiaSet  `json:"katavasies"`
	}

	info := DailyInfo{
		Date:          date.Format("2006-01-02"),
		DateFormatted: formatGreekDate(date),
		Tone:          tone,
		Period:        period,
		FeastName:     menologion.FeastName,
		Fasting:       fasting,
		Saints:        menologion.Saints,
		Epistle:       epistleReading,
		Gospel:        gospelReading,
		MovableCycle:  movable,
		Katavasies:    katavasies,
	}

	json.NewEncoder(w).Encode(info)
}

func handleCategories(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(GetAllCategories())
}

func handlePrayerService(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	id := r.URL.Query().Get("id")
	if id == "" {
		http.Error(w, `{"error": "id parameter required"}`, http.StatusBadRequest)
		return
	}

	date := parseDateQuery(r)
	saintIdx := 0
	if sParam := r.URL.Query().Get("saint_idx"); sParam != "" {
		if val, err := strconv.Atoi(sParam); err == nil && val >= 0 {
			saintIdx = val
		}
	}

	service, err := BuildService(id, date, saintIdx)
	if err != nil {
		http.Error(w, fmt.Sprintf(`{"error": "%s"}`, err.Error()), http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(service)
}

func handleSynaxarion(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	date := parseDateQuery(r)
	menologion := GetDailySaints(int(date.Month()), date.Day())

	json.NewEncoder(w).Encode(map[string]interface{}{
		"date":           date.Format("2006-01-02"),
		"date_formatted": formatGreekDate(date),
		"feast_name":     menologion.FeastName,
		"saints":         menologion.Saints,
	})
}

func handleFavorites(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	if r.Method == http.MethodGet {
		favs, err := GetFavorites()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		json.NewEncoder(w).Encode(favs)
		return
	}

	if r.Method == http.MethodPost {
		var payload struct {
			ID        string `json:"id"`
			ServiceID string `json:"service_id"`
			Note      string `json:"note"`
		}
		if err := json.NewDecoder(r.Body).Decode(&payload); err != nil || payload.ServiceID == "" {
			http.Error(w, `{"error": "invalid payload"}`, http.StatusBadRequest)
			return
		}
		if payload.ID == "" {
			payload.ID = fmt.Sprintf("fav_%d", time.Now().UnixNano())
		}
		if err := AddFavorite(payload.ID, payload.ServiceID, payload.Note); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		json.NewEncoder(w).Encode(map[string]interface{}{"status": "success", "id": payload.ID})
		return
	}

	http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
}

func handleFavoriteByID(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodDelete {
		id := strings.TrimPrefix(r.URL.Path, "/api/v1/prayers/favorites/")
		if id == "" {
			http.Error(w, "ID required", http.StatusBadRequest)
			return
		}
		if err := RemoveFavorite(id); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{"status": "deleted", "id": id})
		return
	}
	http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
}

func getStandardRuleItems() []PrayerRuleItem {
	return []PrayerRuleItem{
		{
			ID:          "morning_prayer",
			Title:       "Πρωινή Προσευχή",
			Description: "Εξέγερσις εκ του ύπνου & Τρισάγιον",
			Icon:        "sun",
			Points:      25,
		},
		{
			ID:          "gospel_reading",
			Title:       "Ανάγνωση Ευαγγελίου",
			Description: "Ημερήσιο Αποστολικό & Ευαγγελικό ανάγνωσμα",
			Icon:        "book",
			Points:      15,
		},
		{
			ID:          "jesus_prayer",
			Title:       "Νοερά Προσευχή (Κομποσχοίνι)",
			Description: "Κανόνας 100 κόμβων «Κύριε Ιησού Χριστέ...»",
			Icon:        "komboskini",
			Points:      20,
		},
		{
			ID:          "small_compline",
			Title:       "Μικρόν Απόδειπνον",
			Description: "Προσευχή προ του ύπνου & Άσπιλε Αμόλυντε",
			Icon:        "moon",
			Points:      25,
		},
	}
}

func handlePrayerRuleToday(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	date := parseDateQuery(r)
	dateStr := date.Format("2006-01-02")

	completedMap, _ := GetCompletedItemsForDate(dateStr)
	items := getStandardRuleItems()
	completedCount := 0
	totalPoints := 0

	for i := range items {
		if cAt, ok := completedMap[items[i].ID]; ok {
			items[i].Completed = true
			items[i].CompletedAt = cAt
			completedCount++
			totalPoints += items[i].Points
		}
	}

	streak := GetPrayerStreak()

	status := DailyPrayerRuleStatus{
		Date:              dateStr,
		Items:             items,
		CompletedCount:    completedCount,
		TotalCount:        len(items),
		TotalPointsEarned: totalPoints,
		StreakDays:        streak,
	}

	json.NewEncoder(w).Encode(status)
}

func handlePrayerRuleComplete(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	w.Header().Set("Content-Type", "application/json")

	var payload struct {
		ServiceID   string `json:"service_id"`
		DurationSec int    `json:"duration_sec"`
	}
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil || payload.ServiceID == "" {
		http.Error(w, `{"error": "service_id required"}`, http.StatusBadRequest)
		return
	}

	username := getUsername(r)
	logID := fmt.Sprintf("log_%d", time.Now().UnixNano())
	if err := LogPrayerCompletion(logID, username, payload.ServiceID, payload.DurationSec); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Calculate star points
	awardPoints := 20
	ruleName := "Κανόνας Προσευχής"
	for _, item := range getStandardRuleItems() {
		if item.ID == payload.ServiceID {
			awardPoints = item.Points
			ruleName = item.Title
			break
		}
	}

	// Award RPG / Star points!
	newBalance := points.AddPointsWithEvent(
		username,
		awardPoints,
		fmt.Sprintf("Ορθόδοξο Προσευχητάρι: Ολοκλήρωση %s", ruleName),
	)

	streak := GetPrayerStreak()

	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":         "completed",
		"service_id":     payload.ServiceID,
		"points_awarded": awardPoints,
		"new_balance":    newBalance,
		"streak_days":    streak,
	})
}

func handleTypikonToday(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	date := parseDateQuery(r)
	vars := ResolveLiturgicalVariables(date)
	json.NewEncoder(w).Encode(vars)
}

func handleTypikonKatavasies(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	date := parseDateQuery(r)
	katavasies := GetSeasonalKatavasies(date)
	json.NewEncoder(w).Encode(katavasies)
}

func handleTypikonVariables(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	date := parseDateQuery(r)
	vars := ResolveLiturgicalVariables(date)
	json.NewEncoder(w).Encode(vars)
}

func handleParaklesisSaint(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	q := r.URL.Query()
	name := q.Get("name")
	title := q.Get("title")
	apol := q.Get("apolytikion")

	if name == "" {
		date := parseDateQuery(r)
		men := GetDailySaints(int(date.Month()), date.Day())
		if len(men.Saints) > 0 {
			name = men.Saints[0].Name
			title = men.Saints[0].Title
			apol = men.Saints[0].Apolytikion
		}
	}

	svc := BuildGenericSaintParaklesis(name, title, apol)
	json.NewEncoder(w).Encode(svc)
}


