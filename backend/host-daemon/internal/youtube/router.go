package youtube

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/youtube/videos", handleVideos)
	mux.HandleFunc("/api/v1/youtube/search", handleSearch)
	mux.HandleFunc("/api/v1/youtube/streams", handleStreams)
	mux.HandleFunc("/api/v1/youtube/stream", handleStream)
	mux.HandleFunc("/api/v1/youtube/download", handleDownload)
	mux.HandleFunc("/api/v1/youtube/session/start", handleSessionStart)
	mux.HandleFunc("/api/v1/youtube/session", handleSessionStatus)
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

// handleSearch proxies NewPipe search to the bridge.
func handleSearch(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var payload struct {
		Query string `json:"query"`
	}
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil || strings.TrimSpace(payload.Query) == "" {
		http.Error(w, "Missing query", http.StatusBadRequest)
		return
	}
	results, err := bridgeSearch(strings.TrimSpace(payload.Query))
	if err != nil {
		log.Printf("youtube search: %v", err)
		http.Error(w, "Search failed", http.StatusBadGateway)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(results)
}

// handleStreams returns resolved stream metadata (mp4 + hls) for live playback.
func handleStreams(w http.ResponseWriter, r *http.Request) {
	id := strings.TrimSpace(r.URL.Query().Get("id"))
	if id == "" {
		http.Error(w, "Missing video id", http.StatusBadRequest)
		return
	}
	meta, err := bridgeStreams(id)
	// ponytail: NewPipe cannot resolve some live streams (YouTube blocks the
	// clients it uses); fall back to yt-dlp for the HLS manifest only.
	if err != nil || (meta.Mp4 == "" && meta.Hls == "") {
		if hls, herr := liveHlsFallback(id); herr == nil && hls != "" {
			meta = &streamMeta{ID: id, Live: true, Hls: hls}
		} else {
			log.Printf("youtube streams %s: %v (live fallback: %v)", id, err, herr)
			http.Error(w, "Stream resolution failed", http.StatusBadGateway)
			return
		}
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(meta)
}

// handleStream 302-redirects to the direct mp4 so the client plays in one hop
// (same pattern as the music module's ytstream).
func handleStream(w http.ResponseWriter, r *http.Request) {
	id := strings.TrimSpace(r.URL.Query().Get("id"))
	if id == "" {
		http.Error(w, "Missing video id", http.StatusBadRequest)
		return
	}
	meta, err := bridgeStreams(id)
	if err != nil {
		log.Printf("youtube stream %s: %v", id, err)
		http.Error(w, "Stream resolution failed", http.StatusBadGateway)
		return
	}
	if meta.Mp4 == "" {
		http.Error(w, "No mp4 stream (live streams use /streams)", http.StatusBadGateway)
		return
	}
	http.Redirect(w, r, meta.Mp4, http.StatusFound)
}

func handleDownload(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var payload struct {
		ID string `json:"id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil || payload.ID == "" {
		http.Error(w, "Missing video id", http.StatusBadRequest)
		return
	}
	log.Printf("Starting NewPipe download for video id: %s", payload.ID)

	go func(id string) {
		meta, err := bridgeStreams(id)
		if err != nil || meta.Mp4 == "" {
			log.Printf("youtube download %s: stream resolution failed: %v", id, err)
			return
		}
		fname := sanitize(meta.Title) + ".mp4"
		path := filepath.Join("./data/media", fname)
		req, err := http.NewRequest(http.MethodGet, meta.Mp4, nil)
		if err != nil {
			log.Printf("youtube download %s: %v", id, err)
			return
		}
		req.Header.Set("User-Agent", bridgeUA)
		res, err := http.DefaultClient.Do(req)
		if err != nil {
			log.Printf("youtube download %s: %v", id, err)
			return
		}
		defer res.Body.Close()
		if res.StatusCode != http.StatusOK {
			log.Printf("youtube download %s: http %s", id, res.Status)
			return
		}
		out, err := os.Create(path)
		if err != nil {
			log.Printf("youtube download %s: %v", id, err)
			return
		}
		written, err := io.Copy(out, res.Body)
		out.Close()
		if err != nil {
			log.Printf("youtube download %s: %v", id, err)
			return
		}

		_, dbErr := DB.Exec(
			"INSERT INTO videos (id, title, size) VALUES (?, ?, ?) "+
				"ON CONFLICT(id) DO UPDATE SET title=excluded.title, size=excluded.size",
			id, meta.Title, humanSize(written))
		if dbErr != nil {
			log.Printf("youtube download %s: db update: %v", id, dbErr)
		} else {
			log.Printf("youtube download finished: %s (%s)", path, humanSize(written))
		}
	}(payload.ID)

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "download_started"})
}

func sanitize(name string) string {
	repl := strings.NewReplacer(`\`, "_", "/", "_", ":", "_", "*", "_", "?", "_", `"`, "_", "<", "_", ">", "_", "|", "_")
	s := strings.TrimSpace(repl.Replace(name))
	if s == "" {
		return "video"
	}
	return s
}

func humanSize(bytes int64) string {
	if bytes >= 1<<30 {
		return fmt.Sprintf("%.1f GB", float64(bytes)/(1<<30))
	}
	return fmt.Sprintf("%.1f MB", float64(bytes)/(1<<20))
}