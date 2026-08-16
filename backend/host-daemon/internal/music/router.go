package music

import (
	"encoding/json"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"lifeos/host-daemon/internal/bus"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("GET /api/v1/music/tracks", HandleGetTracks)
	mux.HandleFunc("GET /api/v1/music/tracks/{id}", HandleGetTrack)
	mux.HandleFunc("DELETE /api/v1/music/tracks/{id}", HandleDeleteTrack)
	mux.HandleFunc("DELETE /api/v1/music/tracks", HandleDeleteTrack)
	mux.HandleFunc("/api/v1/music/stream/", HandleGetStream)
	mux.HandleFunc("/api/v1/music/lyrics", HandleGetLyrics)
	mux.HandleFunc("/api/v1/music/search", HandleSearch)
	mux.HandleFunc("/api/v1/music/download", HandleDownload)
	mux.HandleFunc("/api/v1/music/resolve", HandleResolveStreamURL)
	mux.HandleFunc("/api/v1/music/ytstream/", HandleYTStream)
}

type Track struct {
	ID        string  `json:"id"`
	Title     string  `json:"title"`
	Artist    string  `json:"artist"`
	Album     string  `json:"album"`
	FilePath  string  `json:"file_path"`
	Duration  float64 `json:"duration"`
	Thumbnail string  `json:"thumbnail"`
}

func HandleGetTracks(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	query := "SELECT id, title, artist, album, file_path, duration, thumbnail FROM music_tracks"
	var args []any
	if q := strings.TrimSpace(r.URL.Query().Get("q")); q != "" {
		query += " WHERE title LIKE ? OR artist LIKE ? OR album LIKE ?"
		args = append(args, "%"+q+"%", "%"+q+"%", "%"+q+"%")
	}
	query += " ORDER BY artist, title"

	rows, err := DB.Query(query, args...)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var tracks []Track
	for rows.Next() {
		var t Track
		if err := rows.Scan(&t.ID, &t.Title, &t.Artist, &t.Album, &t.FilePath, &t.Duration, &t.Thumbnail); err == nil {
			tracks = append(tracks, t)
		}
	}

	if tracks == nil {
		tracks = []Track{}
	}

	json.NewEncoder(w).Encode(tracks)
}

// HandleGetTrack serves a single track by id (embed card render).
func HandleGetTrack(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	id := r.PathValue("id")

	var t Track
	if err := DB.QueryRow("SELECT id, title, artist, album, file_path, duration, thumbnail FROM music_tracks WHERE id = ?", id).
		Scan(&t.ID, &t.Title, &t.Artist, &t.Album, &t.FilePath, &t.Duration, &t.Thumbnail); err != nil {
		http.Error(w, "Track not found", http.StatusNotFound)
		return
	}
	json.NewEncoder(w).Encode(t)
}

func HandleGetStream(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, HEAD, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "*")
	w.Header().Set("Access-Control-Expose-Headers", "Content-Length, Content-Range, Accept-Ranges, Content-Type")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	trackID := r.URL.Query().Get("id")
	if trackID == "" {
		http.Error(w, "Missing track ID", http.StatusBadRequest)
		return
	}

	var filePath string
	err := DB.QueryRow("SELECT file_path FROM music_tracks WHERE id = ?", trackID).Scan(&filePath)
	if err == nil && filePath != "" {
		if stat, statErr := os.Stat(filePath); statErr == nil {
			file, openErr := os.Open(filePath)
			if openErr == nil {
				defer file.Close()
				w.Header().Set("Accept-Ranges", "bytes")
				http.ServeContent(w, r, filepath.Base(filePath), stat.ModTime(), file)
				return
			}
		}
	}

	// If not available locally on disk, stream live via YouTube
	HandleYTStream(w, r)
}

func HandleDeleteTrack(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "DELETE, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	id := r.PathValue("id")
	if id == "" {
		id = r.URL.Query().Get("id")
	}
	if id == "" {
		http.Error(w, "Missing track id", http.StatusBadRequest)
		return
	}

	var filePath string
	_ = DB.QueryRow("SELECT file_path FROM music_tracks WHERE id = ?", id).Scan(&filePath)
	if filePath != "" {
		_ = os.Remove(filePath)
	}

	// Also remove cache file if any
	cachePath := filepath.Join(DataDir, "music_cache", id+".mp4")
	_ = os.Remove(cachePath)

	_, err := DB.Exec("DELETE FROM music_tracks WHERE id = ?", id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	bus.Publish(bus.Event{
		Topic: "music:deleted",
		Payload: map[string]any{
			"track_id": id,
		},
	})

	json.NewEncoder(w).Encode(map[string]any{"status": "deleted", "id": id})
}
