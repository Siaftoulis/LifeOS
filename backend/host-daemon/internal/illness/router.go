package illness

import (
	"encoding/json"
	"net/http"
	"time"
)

type IllnessState struct {
	ID         string  `json:"id"`
	Type       string  `json:"type"` // "stasis", "injury", "illness"
	BaseDays   float64 `json:"base_days"`
	ActualDays float64 `json:"actual_days"`
	StartTime  int64   `json:"start_time"`
	IsActive   bool    `json:"is_active"`
}

var currentIllness *IllnessState

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/illness/current", handleGetCurrentIllness)
	mux.HandleFunc("/api/v1/illness/apply", handleApplyIllness)
	mux.HandleFunc("/api/v1/illness/recover", handleRecoverIllness)
}

func handleGetCurrentIllness(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if currentIllness == nil || !currentIllness.IsActive {
		json.NewEncoder(w).Encode(map[string]interface{}{"status": "healthy"})
		return
	}

	json.NewEncoder(w).Encode(currentIllness)
}

func handleApplyIllness(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		Type     string  `json:"type"`
		BaseDays float64 `json:"base_days"`
		WP       float64 `json:"willpower"` // Current willpower passed from client or fetched from player service
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid payload", http.StatusBadRequest)
		return
	}

	// Recovery Formula
	// Actual Days = BaseDays * (1 - min(WP, 150) / 300)
	effectiveWP := req.WP
	if effectiveWP > 150 {
		effectiveWP = 150
	}

	actualDays := req.BaseDays * (1.0 - (effectiveWP / 300.0))

	currentIllness = &IllnessState{
		ID:         "ill_" + time.Now().Format("20060102150405"),
		Type:       req.Type,
		BaseDays:   req.BaseDays,
		ActualDays: actualDays,
		StartTime:  time.Now().Unix(),
		IsActive:   true,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(currentIllness)
}

func handleRecoverIllness(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	if currentIllness != nil {
		currentIllness.IsActive = false
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "recovered"})
}
