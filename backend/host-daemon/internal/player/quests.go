package player

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"lifeos/host-daemon/internal/auth/middleware"
	"lifeos/host-daemon/internal/points"
)

func currentUsername(r *http.Request) string {
	if u, ok := r.Context().Value(middleware.UserContextKey).(string); ok && u != "" {
		return u
	}
	return "anonymous"
}

func isAdmin(r *http.Request) bool {
	role, _ := r.Context().Value(middleware.RoleContextKey).(string)
	return role == "ADMIN"
}

func logQuestAction(questID, action, userID string) {
	id := fmt.Sprintf("ql-%d", time.Now().UnixNano())
	DB.Exec("INSERT INTO quest_logs (id, quest_id, action, user_id, timestamp) VALUES (?, ?, ?, ?, ?)",
		id, questID, action, userID, time.Now().Unix())
}

// Penalty for cancelling an accepted quest: half the reward, rounded up.
func questCancelPenalty(xpReward int) int {
	return (xpReward + 1) / 2
}

func handleAcceptQuest(w http.ResponseWriter, r *http.Request) {
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

	var status, acceptedBy string
	err := DB.QueryRow("SELECT status, accepted_by FROM quests WHERE id = ?", payload.QuestID).Scan(&status, &acceptedBy)
	if err != nil {
		http.Error(w, "Quest not found", http.StatusNotFound)
		return
	}
	if acceptedBy != "" {
		http.Error(w, fmt.Sprintf("Quest already claimed by %s", acceptedBy), http.StatusConflict)
		return
	}
	if status != "POOL" && status != "ACTIVE" && status != "MAIN" {
		http.Error(w, "Quest is not claimable", http.StatusConflict)
		return
	}

	user := currentUsername(r)
	if user == "anonymous" {
		http.Error(w, "Unauthenticated", http.StatusUnauthorized)
		return
	}

	_, err = DB.Exec("UPDATE quests SET accepted_by = ?, status = 'ACTIVE' WHERE id = ?", user, payload.QuestID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	logQuestAction(payload.QuestID, "ACCEPTED", user)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "success", "accepted_by": user})
}

func handleCancelQuest(w http.ResponseWriter, r *http.Request) {
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
	var acceptedBy, status, title string
	err := DB.QueryRow("SELECT xp_reward, accepted_by, status, title FROM quests WHERE id = ?", payload.QuestID).
		Scan(&xpReward, &acceptedBy, &status, &title)
	if err != nil {
		http.Error(w, "Quest not found", http.StatusNotFound)
		return
	}
	if status == "DONE" {
		http.Error(w, "Quest already completed", http.StatusConflict)
		return
	}
	if acceptedBy == "" {
		http.Error(w, "Quest is not claimed", http.StatusConflict)
		return
	}

	user := currentUsername(r)
	if user != acceptedBy && !isAdmin(r) {
		http.Error(w, "Only the member who accepted this quest can cancel it", http.StatusForbidden)
		return
	}

	penalty := questCancelPenalty(xpReward)
	points.AddPointsWithEvent(user, -penalty, fmt.Sprintf("Quest Cancelled: %s", title))

	_, err = DB.Exec("UPDATE quests SET accepted_by = '', status = 'POOL' WHERE id = ?", payload.QuestID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	logQuestAction(payload.QuestID, "CANCELLED", user)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":       "success",
		"penalty":      penalty,
		"new_balance":  points.GetBalance(user),
	})
}
