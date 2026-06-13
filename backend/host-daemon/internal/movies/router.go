package movies

import (
	"encoding/json"
	"net/http"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/movies", HandleGetMovies)
	mux.HandleFunc("/api/v1/movies/watchlist", HandleAddToWatchlist)
	mux.HandleFunc("/api/v1/movies/subtitles", HandleGetSubtitles)
}

func HandleGetMovies(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode([]map[string]interface{}{
		{"id": "m1", "title": "Inception", "status": "AVAILABLE"},
		{"id": "m2", "title": "Interstellar", "status": "WATCHED"},
		{"id": "m3", "title": "Dune", "status": "DOWNLOADING"},
	})
}

func HandleAddToWatchlist(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "added",
		"message": "Movie pushed to download pipeline successfully.",
	})
}

func HandleGetSubtitles(w http.ResponseWriter, r *http.Request) {
	imdbId := r.URL.Query().Get("imdb_id")
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode([]map[string]interface{}{
		{"lang": "el", "url": "stub_download_link_el", "imdb_id": imdbId},
		{"lang": "en", "url": "stub_download_link_en", "imdb_id": imdbId},
	})
}
