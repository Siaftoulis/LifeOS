package player

import (
	"encoding/json"
	"net/http"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/player/stats", handleGetStats)
	mux.HandleFunc("/api/v1/player/task/complete", handleTaskComplete)
}

func handleGetStats(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	ApplyDecay()
	state := GetPlayerState()
	age := state.Age
	xp := state.XP
	wp := state.Willpower

	bc := CalculateBiologicalCap(age)
	rawLevel := CalculateRawLevel(xp)
	effectiveLevel := CalculateEffectiveLevel(xp, age)

	resp := map[string]interface{}{
		"age":                 age,
		"xp":                  xp,
		"willpower":           wp,
		"biological_cap":      bc,
		"raw_level":           rawLevel,
		"effective_level":     effectiveLevel,
		"next_level_xp":       CalculateLifetimeXP(float64(effectiveLevel + 1)),
		"atrophy_buffer_days": CalculateAtrophyBuffer(wp),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

func handleTaskComplete(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var payload struct {
		TaskID     string `json:"task_id"`
		Attribute  string `json:"attribute"`
		BaseXP     int    `json:"base_xp"`
		BasePoints int    `json:"base_points"`
		IsSick     bool   `json:"is_sick"`
	}

	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		http.Error(w, "Invalid payload", http.StatusBadRequest)
		return
	}

	task := TaskCompletion{
		TaskID:     payload.TaskID,
		Attribute:  payload.Attribute,
		BaseXP:     payload.BaseXP,
		BasePoints: payload.BasePoints,
		IsSick:     payload.IsSick,
	}

	reward := ProcessTaskCompletion(task)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "success",
		"reward": reward,
	})
}
