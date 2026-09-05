package music

import (
	"encoding/json"
	"net/http"

	"lifeos/host-daemon/internal/auth/middleware"
)

// HandleDownload validates incoming video download requests and enqueues them for background processing.
func HandleDownload(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var payload struct {
		VideoID   string `json:"video_id"`
		Thumbnail string `json:"thumbnail"`
	}
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil || payload.VideoID == "" {
		http.Error(w, "Missing video_id", http.StatusBadRequest)
		return
	}

	username, _ := r.Context().Value(middleware.UserContextKey).(string)

	queueID, err := EnqueueDownload(payload.VideoID, payload.Thumbnail, 0, username)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"status":   "download_started",
		"queue_id": queueID,
		"id":       queueID,
	})
}
