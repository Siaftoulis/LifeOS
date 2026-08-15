package player

import (
	"encoding/json"
	"fmt"
	"lifeos/host-daemon/internal/points"
	"net/http"
	"strconv"
	"strings"
	"time"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/player/stats", handleGetStats)
	mux.HandleFunc("/api/v1/player/task/complete", handleTaskComplete)
	mux.HandleFunc("/api/v1/rpg/quests", handleGetQuests)
	mux.HandleFunc("/api/v1/rpg/quests/complete", handleQuestComplete)
	mux.HandleFunc("/api/v1/rpg/quests/add", handleAddQuest)
	mux.HandleFunc("/api/v1/rpg/quests/activate", handleActivateQuest)
	mux.HandleFunc("/api/v1/rpg/quests/accept", handleAcceptQuest)
	mux.HandleFunc("/api/v1/rpg/quests/cancel", handleCancelQuest)
	mux.HandleFunc("/api/v1/rpg/quests/delete", handleDeleteQuest)
	mux.HandleFunc("/api/v1/rpg/quests/update", handleUpdateQuest)
	mux.HandleFunc("/api/v1/rpg/quests/add-main", handleAddMainQuest)
}

type Quest struct {
	ID            string `json:"id"`
	Title         string `json:"title"`
	Description   string `json:"description"`
	XpReward      int    `json:"xp_reward"`
	Status        string `json:"status"`
	AssignedUsers string `json:"assigned_users"`
	Progress      int    `json:"progress"`
	AcceptedBy    string `json:"accepted_by"`
	DueDate       string `json:"due_date"`
	CreatedBy     string `json:"created_by"`
}

func handleGetQuests(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	w.Header().Set("Content-Type", "application/json")

	rows, err := DB.Query("SELECT id, title, description, xp_reward, status, assigned_users, progress, accepted_by, due_date, created_by FROM quests")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var quests []Quest
	for rows.Next() {
		var q Quest
		if err := rows.Scan(&q.ID, &q.Title, &q.Description, &q.XpReward, &q.Status, &q.AssignedUsers, &q.Progress, &q.AcceptedBy, &q.DueDate, &q.CreatedBy); err == nil {
			quests = append(quests, q)
		}
	}
	if err := rows.Err(); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if quests == nil {
		quests = []Quest{}
	}

	json.NewEncoder(w).Encode(quests)
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
		"attributes":          state.Attributes,
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

func handleQuestComplete(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var payload struct {
		QuestID string `json:"quest_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		http.Error(w, "Invalid payload", http.StatusBadRequest)
		return
	}

	var xpReward int
	var assignedUsers, acceptedBy, status, title string
	err := DB.QueryRow("SELECT xp_reward, assigned_users, accepted_by, status, title FROM quests WHERE id = ?", payload.QuestID).
		Scan(&xpReward, &assignedUsers, &acceptedBy, &status, &title)
	if err != nil {
		http.Error(w, "Quest not found", http.StatusNotFound)
		return
	}
	if status == "DONE" {
		http.Error(w, "Quest already completed", http.StatusConflict)
		return
	}
	if acceptedBy == "" {
		http.Error(w, "Quest must be accepted before completing", http.StatusBadRequest)
		return
	}

	user := currentUsername(r)
	if user != acceptedBy && !isAdmin(r) {
		http.Error(w, "Only the member who accepted this quest can complete it", http.StatusForbidden)
		return
	}

	// Update quest status to DONE
	_, err = DB.Exec("UPDATE quests SET status = 'DONE', progress = 100 WHERE id = ?", payload.QuestID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Award XP (family player)
	UpdatePlayerXP(xpReward)

	// Award points: per-user splits if configured, otherwise to the acceptor
	if assignedUsers == "" {
		points.AddPointsWithEvent(acceptedBy, xpReward, fmt.Sprintf("Completed Quest: %s", title))
	} else {
		parts := strings.Split(assignedUsers, ",")
		for _, p := range parts {
			kv := strings.Split(p, ":")
			if len(kv) == 2 {
				u := kv[0]
				pts, _ := strconv.Atoi(kv[1])
				points.AddPointsWithEvent(u, pts, fmt.Sprintf("Completed Quest: %s (split)", title))
			}
		}
	}
	logQuestAction(payload.QuestID, "COMPLETED", user)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  "success",
		"xp":      xpReward,
		"awarded": acceptedBy,
	})
}

func handleAddQuest(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var payload struct {
		Title         string `json:"title"`
		Description   string `json:"description"`
		XpReward      int    `json:"xp_reward"`
		AssignedUsers string `json:"assigned_users"`
		DueDate       string `json:"due_date"`
	}

	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		http.Error(w, "Invalid payload", http.StatusBadRequest)
		return
	}

	id := fmt.Sprintf("q-%d", time.Now().UnixNano())
	_, err := DB.Exec("INSERT INTO quests (id, title, description, xp_reward, status, assigned_users, progress, due_date, created_by, created_at) VALUES (?, ?, ?, ?, 'POOL', ?, 0, ?, ?, ?)",
		id, payload.Title, payload.Description, payload.XpReward, payload.AssignedUsers, payload.DueDate, currentUsername(r), time.Now().Unix())
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "success", "id": id})
}

func handleActivateQuest(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var payload struct {
		QuestID string `json:"quest_id"`
	}

	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		http.Error(w, "Invalid payload", http.StatusBadRequest)
		return
	}

	_, err := DB.Exec("UPDATE quests SET status = 'ACTIVE' WHERE id = ?", payload.QuestID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "success"})
}

func handleDeleteQuest(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var payload struct {
		QuestID string `json:"quest_id"`
	}

	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		http.Error(w, "Invalid payload", http.StatusBadRequest)
		return
	}

	_, err := DB.Exec("DELETE FROM quests WHERE id = ?", payload.QuestID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "success"})
}

func handleUpdateQuest(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var payload struct {
		QuestID       string `json:"quest_id"`
		Title         string `json:"title"`
		Description   string `json:"description"`
		XpReward      int    `json:"xp_reward"`
		AssignedUsers string `json:"assigned_users"`
		Progress      int    `json:"progress"`
	}

	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		http.Error(w, "Invalid payload", http.StatusBadRequest)
		return
	}

	_, err := DB.Exec("UPDATE quests SET title = ?, description = ?, xp_reward = ?, assigned_users = ?, progress = ? WHERE id = ?", payload.Title, payload.Description, payload.XpReward, payload.AssignedUsers, payload.Progress, payload.QuestID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "success"})
}

func handleAddMainQuest(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var payload struct {
		Title       string `json:"title"`
		Description string `json:"description"`
		XpReward    int    `json:"xp_reward"`
	}

	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		http.Error(w, "Invalid payload", http.StatusBadRequest)
		return
	}

	// Delete any existing MAIN quest first
	_, _ = DB.Exec("DELETE FROM quests WHERE status = 'MAIN'")

	id := fmt.Sprintf("q-main-%d", len(payload.Title)+payload.XpReward)
	_, err := DB.Exec("INSERT INTO quests (id, title, description, xp_reward, status, assigned_users, progress) VALUES (?, ?, ?, ?, 'MAIN', '', 0)", id, payload.Title, payload.Description, payload.XpReward)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "success", "id": id})
}
