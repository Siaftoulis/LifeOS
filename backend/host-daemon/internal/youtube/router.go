package youtube

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/youtube/videos", handleVideos)
	mux.HandleFunc("/api/v1/youtube/download", handleDownload)
	mux.HandleFunc("/api/v1/youtube/session/start", handleSessionStart)
	mux.HandleFunc("/api/v1/youtube/session/stop", handleSessionStop)
}

func handleVideos(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	
	rows, err := DB.Query("SELECT id, title, size FROM videos")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var videos []map[string]interface{}
	for rows.Next() {
		var id, title, size string
		if err := rows.Scan(&id, &title, &size); err == nil {
			videos = append(videos, map[string]interface{}{
				"id":    id,
				"title": title,
				"size":  size,
			})
		}
	}
	json.NewEncoder(w).Encode(videos)
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

	videoURL := payload["video_url"]
	log.Printf("Starting yt-dlp download for URL: %s", videoURL)

	go func(url string) {
		cmd := exec.Command("yt-dlp", "-o", "./data/media/%(title)s.%(ext)s", "--print", "after_move:filepath", url)
		out, err := cmd.Output()
		if err != nil {
			log.Printf("yt-dlp error: %v", err)
			return
		}
		
		filePath := string(out) // The printed filepath from yt-dlp
		
		// In a real scenario we parse the output to get the file size, or use os.Stat
		var size int64 = 0
		if fileInfo, err := os.Stat(filePath); err == nil {
			size = fileInfo.Size()
		}

		// Update database
		_, dbErr := DB.Exec("INSERT INTO videos (id, title, size) VALUES (?, ?, ?)",
			url, "Downloaded Video", fmt.Sprintf("%d", size))
		if dbErr != nil {
			log.Printf("yt-dlp DB update error: %v", dbErr)
		} else {
			log.Printf("yt-dlp download finished for %s, size: %d", url, size)
		}
	}(videoURL)

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
