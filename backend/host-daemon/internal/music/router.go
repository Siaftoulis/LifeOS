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

func HandleGetTracks(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode([]map[string]interface{}{
		{"id": "t1", "title": "Nightcall", "artist": "Kavinsky", "album": "OutRun"},
		{"id": "t2", "title": "Resonance", "artist": "HOME", "album": "Odyssey"},
		{"id": "t3", "title": "Blinding Lights", "artist": "The Weeknd", "album": "After Hours"},
	})
}

func HandleGetStream(w http.ResponseWriter, r *http.Request) {
	// Stub Accept-Ranges audio stream
	w.Header().Set("Content-Type", "audio/mpeg")
	w.Header().Set("Accept-Ranges", "bytes")
	w.Write([]byte("Stub audio bytes sequence..."))
}

func HandleGetLyrics(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode([]map[string]interface{}{
		{"time": 0.5, "text": "I'm giving you a nightcall to tell you how I feel"},
		{"time": 4.2, "text": "I want to drive you through the night, down the hills"},
	})
}
