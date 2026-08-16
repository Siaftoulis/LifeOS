package music

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"

	"lifeos/host-daemon/internal/auth/middleware"
	"lifeos/host-daemon/internal/bus"
	"lifeos/host-daemon/internal/points"
)

// HandleDownload extracts a YouTube video to mp3 (full metadata + cover art)
// and files it under <data>/media/music/<artist>/<title> [<id>].mp3.
// The artist folder comes straight from yt-dlp's output template.
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

	go func(videoID, thumb, user string) {
		outDir := filepath.Join(DataDir, "media", "music")
		if err := os.MkdirAll(outDir, 0755); err != nil {
			log.Printf("music download %s: mkdir failed: %v", videoID, err)
		}
		cmd := exec.Command("yt-dlp",
			"--js-runtimes", "node:C:\\Program Files\\nodejs\\node.exe,node,bun",
			"--no-warnings",
			"--no-check-certificates",
			"--extractor-args", "youtube:player_client=mweb,web,ios,android,tv",
			"-x", "--audio-format", "mp3", "--audio-quality", "0",
			"--embed-metadata", "--embed-thumbnail", "--add-metadata",
			"--print", "after_move:filepath",
			"--print", "after_move:title",
			"--print", "after_move:artist",
			"--print", "after_move:album",
			"--print", "after_move:duration",
			"--print", "after_move:uploader",
			"-o", filepath.Join(outDir, "%(artist,uploader)s", "%(title)s [%(id)s].%(ext)s"),
			"https://www.youtube.com/watch?v="+videoID)
		out, err := cmd.Output()
		if err != nil {
			log.Printf("music download %s: yt-dlp failed: %v", videoID, err)
			return
		}
		lines := strings.Split(strings.TrimSpace(string(out)), "\n")
		if len(lines) < 6 || lines[0] == "" {
			log.Printf("music download %s: unexpected output: %q", videoID, out)
			return
		}
		// yt-dlp prints "NA" for missing fields; normalize to empty strings.
		clean := func(s string) string {
			s = strings.TrimSpace(s)
			if s == "NA" {
				return ""
			}
			return s
		}
		title := clean(lines[1])
		artist := clean(lines[2])
		album := clean(lines[3])
		if artist == "" {
			artist = clean(lines[5]) // uploader fallback
		}
		duration := 0.0
		if d, err := strconv.ParseFloat(strings.TrimSpace(lines[4]), 64); err == nil {
			duration = d
		}
		savedPath := lines[0]
		_, err = DB.Exec(`INSERT INTO music_tracks (id, title, artist, album, file_path, duration, thumbnail)
			VALUES (?, ?, ?, ?, ?, ?, ?)
			ON CONFLICT(id) DO UPDATE SET title=excluded.title, artist=excluded.artist,
			album=excluded.album, file_path=excluded.file_path, duration=excluded.duration, thumbnail=excluded.thumbnail`,
			videoID, title, artist, album, savedPath, duration, thumb)
		if err != nil {
			log.Printf("music download %s: db insert failed: %v", videoID, err)
			return
		}
		if user != "" {
			points.AddPointsWithEvent(user, 5, "Music: Track Downloaded: "+title)
		}
		bus.Publish(bus.Event{
			Topic:  "music:downloaded",
			UserID: user,
			Payload: map[string]any{
				"track_id":  videoID,
				"title":     title,
				"artist":    artist,
				"album":     album,
				"duration":  duration,
				"file_path": savedPath,
			},
		})
		log.Printf("music download done: %s - %s -> %s", artist, title, savedPath)
	}(payload.VideoID, payload.Thumbnail, username)

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "download_started"})
}