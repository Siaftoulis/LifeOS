package music

import (
	"encoding/json"
	"net/http"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/music/tracks", HandleGetTracks)
	mux.HandleFunc("/api/v1/music/stream", HandleGetStream)
	mux.HandleFunc("/api/v1/music/lyrics", HandleGetLyrics)
}

type Track struct {
	ID     string `json:"id"`
	Title  string `json:"title"`
	Artist string `json:"artist"`
	Album  string `json:"album"`
}

func HandleGetTracks(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	rows, err := DB.Query("SELECT id, title, artist, album FROM music_tracks")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var tracks []Track
	for rows.Next() {
		var t Track
		if err := rows.Scan(&t.ID, &t.Title, &t.Artist, &t.Album); err == nil {
			tracks = append(tracks, t)
		}
	}

	if tracks == nil {
		tracks = []Track{}
	}

	json.NewEncoder(w).Encode(tracks)
}

func HandleGetStream(w http.ResponseWriter, r *http.Request) {
	trackID := r.URL.Query().Get("id")
	if trackID == "" {
		http.Error(w, "Missing track ID", http.StatusBadRequest)
		return
	}

	var filePath string
	err := DB.QueryRow("SELECT file_path FROM music_tracks WHERE id = ?", trackID).Scan(&filePath)
	if err != nil {
		// Fallback to a dummy file if not found in db just to keep it from completely crashing if they don't have music
		filePath = "./data/media/dummy.mp3"
	}

	w.Header().Set("Accept-Ranges", "bytes")
	http.ServeFile(w, r, filePath)
}

func HandleGetLyrics(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode([]map[string]interface{}{
		{"time": 0.5, "text": "I'm giving you a nightcall to tell you how I feel"},
		{"time": 4.2, "text": "I want to drive you through the night, down the hills"},
	})
}
