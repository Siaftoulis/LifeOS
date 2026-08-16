package youtube

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"lifeos/host-daemon/internal/auth/middleware"
	"lifeos/host-daemon/internal/points"
)

const (
	pointsPerHalfHour = 10 // -10 PTS per started 30-minute block
	sessionBlockMin   = 30
)

type sessionInfo struct {
	Active      bool  `json:"active"`
	StartedAt   int64 `json:"started_at"`
	ElapsedMin  int   `json:"elapsed_minutes"`
	EstCost     int   `json:"est_cost"`
}

type sessionEnded struct {
	Status         string `json:"status"`
	ElapsedMin     int    `json:"elapsed_minutes"`
	PointsDeducted int    `json:"points_deducted"`
	NewBalance     int    `json:"new_balance"`
}

func currentUser(r *http.Request) string {
	username, _ := r.Context().Value(middleware.UserContextKey).(string)
	if username == "" {
		username = "panospds"
	}
	return username
}

// getSession returns the user's active session start time, if any.
func getSession(user string) (time.Time, bool) {
	var started int64
	err := DB.QueryRow("SELECT started_at FROM sessions WHERE user_id = ?", user).Scan(&started)
	if err != nil {
		return time.Time{}, false
	}
	return time.Unix(started, 0), true
}

func insertSession(user string, started time.Time) error {
	_, err := DB.Exec("INSERT INTO sessions (user_id, started_at) VALUES (?, ?)", user, started.Unix())
	return err
}

func deleteSession(user string) {
	DB.Exec("DELETE FROM sessions WHERE user_id = ?", user)
}

// chargeAndClose computes the cost of the elapsed session, deducts points and
// clears the session. Shared by stop and by the stale-session recovery path.
func chargeAndClose(user string, started time.Time) sessionEnded {
	elapsedMin := int(time.Since(started).Minutes())
	if elapsedMin < 0 {
		elapsedMin = 0
	}
	cost := blocksFor(elapsedMin) * pointsPerHalfHour
	points.AddPointsWithEvent(user, -cost, "YouTube Session "+fmtMin(elapsedMin))
	deleteSession(user)
	return sessionEnded{
		Status:         "session_ended",
		ElapsedMin:     elapsedMin,
		PointsDeducted: cost,
		NewBalance:     points.GetBalance(user),
	}
}

// blocksFor rounds elapsed minutes up to whole 30-min blocks, min 1.
func blocksFor(elapsedMin int) int {
	blocks := (elapsedMin + sessionBlockMin - 1) / sessionBlockMin
	if blocks < 1 {
		blocks = 1
	}
	return blocks
}

func fmtMin(m int) string {
	if m < 60 {
		return fmt.Sprintf("%dm", m)
	}
	return fmt.Sprintf("%dh%dm", m/60, m%60)
}

func handleSessionStart(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	user := currentUser(r)
	if started, ok := getSession(user); ok {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(sessionInfo{Active: true, StartedAt: started.Unix(),
			ElapsedMin: int(time.Since(started).Minutes()), EstCost: estCost(started)})
		return
	}
	started := time.Now()
	if err := insertSession(user, started); err != nil {
		log.Printf("youtube session start: %v", err)
		http.Error(w, "Could not start session", http.StatusInternalServerError)
		return
	}
	log.Printf("YouTube session started for %s", user)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(sessionInfo{Active: true, StartedAt: started.Unix(), ElapsedMin: 0, EstCost: pointsPerHalfHour})
}

func handleSessionStatus(w http.ResponseWriter, r *http.Request) {
	user := currentUser(r)
	started, ok := getSession(user)
	if !ok {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(sessionInfo{Active: false})
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(sessionInfo{Active: true, StartedAt: started.Unix(),
		ElapsedMin: int(time.Since(started).Minutes()), EstCost: estCost(started)})
}

func estCost(started time.Time) int {
	elapsed := int(time.Since(started).Minutes())
	if elapsed < 0 {
		elapsed = 0
	}
	return blocksFor(elapsed) * pointsPerHalfHour
}

func handleSessionStop(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	user := currentUser(r)
	started, ok := getSession(user)
	if !ok {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(sessionEnded{Status: "no_active_session"})
		return
	}
	result := chargeAndClose(user, started)
	log.Printf("YouTube session ended for %s: %d min, -%d PTS", user, result.ElapsedMin, result.PointsDeducted)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(result)
}