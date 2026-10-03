package music

import (
	"encoding/json"
	"net/http"
	"time"

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
		VideoID     string `json:"video_id"`
		Title       string `json:"title"`
		Artist      string `json:"artist"`
		Thumbnail   string `json:"thumbnail"`
		QualityMode string `json:"quality_mode"`
	}
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil || payload.VideoID == "" {
		http.Error(w, "Missing video_id", http.StatusBadRequest)
		return
	}

	if DB != nil && payload.Title != "" && payload.Artist != "" {
		_, _ = DB.Exec(`INSERT INTO music_tracks (id, title, artist, thumbnail, thumbnail_url, added_at)
			VALUES (?, ?, ?, ?, ?, ?)
			ON CONFLICT(id) DO UPDATE SET title=COALESCE(NULLIF(excluded.title, ''), music_tracks.title),
			artist=COALESCE(NULLIF(excluded.artist, ''), music_tracks.artist),
			thumbnail=COALESCE(NULLIF(excluded.thumbnail, ''), music_tracks.thumbnail)`,
			payload.VideoID, payload.Title, payload.Artist, payload.Thumbnail, payload.Thumbnail, time.Now().UnixMilli())
	}

	username, _ := r.Context().Value(middleware.UserContextKey).(string)

	queueID, err := EnqueueDownload(payload.VideoID, payload.Thumbnail, 0, username, payload.QualityMode)
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
