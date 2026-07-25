package chtm

import (
	"encoding/json"
	"net/http"
	"time"

	"lifeos/host-daemon/internal/auth/middleware"
)

type ChtmStats struct {
	TotalHabits       int    `json:"total_habits"`
	ActiveStreaks     int    `json:"active_streaks"`
	WeeklyCheckins    int    `json:"weekly_checkins"`
	CompletionRatePct float64 `json:"completion_rate_pct"`
	UpdatedAt         int64  `json:"updated_at"`
}

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/chtm/stats", middleware.RequireAuth(HandleChtmStats))
}

func HandleChtmStats(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	stats := ChtmStats{
		TotalHabits:       8,
		ActiveStreaks:     5,
		WeeklyCheckins:    24,
		CompletionRatePct: 87.5,
		UpdatedAt:         time.Now().Unix(),
	}

	json.NewEncoder(w).Encode(stats)
}
