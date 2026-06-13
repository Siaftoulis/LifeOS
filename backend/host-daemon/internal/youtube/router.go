package youtube

import (
	"encoding/json"
	"log"
	"net/http"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/youtube/videos", handleVideos)
	mux.HandleFunc("/api/v1/youtube/download", handleDownload)
	mux.HandleFunc("/api/v1/youtube/session/start", handleSessionStart)
	mux.HandleFunc("/api/v1/youtube/session/stop", handleSessionStop)
}

func handleVideos(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	// Stub downloaded media list
	json.NewEncoder(w).Encode([]map[string]interface{}{
		{"id": "yt_1", "title": "Flutter Tutorial - State Management", "size": "345 MB"},
		{"id": "yt_2", "title": "Lofi Hip Hop Radio 24/7", "size": "1.2 GB"},
		{"id": "yt_3", "title": "Tech News Weekly", "size": "128 MB"},
	})
}

func handleDownload(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var payload map[string]string
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		http.Error(w, "Bad Request", http.StatusBadRequest)
		return
	}
	// Stub yt-dlp execution
	log.Printf("yt-dlp download triggered for URL: %s", payload["video_url"])
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "download_started"})
}

func handleSessionStart(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	log.Printf("YouTube Session Started. Point deductions will apply (-10 PTS / 30 mins)")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "session_active"})
}

func handleSessionStop(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	log.Printf("YouTube Session Stopped. Points ledger updated.")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "session_ended", "points_deducted": "10"})
}
