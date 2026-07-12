package movies

import (
	"encoding/json"
	"net/http"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/movies", HandleGetMovies)
	mux.HandleFunc("/api/v1/movies/watchlist", HandleAddToWatchlist)
	mux.HandleFunc("/api/v1/movies/subtitles", HandleGetSubtitles)
	mux.HandleFunc("/api/v1/movies/subs", HandleServeSubtitle)
}

func HandleGetMovies(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	rows, err := DB.Query("SELECT id, title, director, release_year, color_hex, status FROM movies")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var moviesList []Movie
	for rows.Next() {
		var m Movie
		if err := rows.Scan(&m.ID, &m.Title, &m.Director, &m.Year, &m.ColorHex, &m.Status); err != nil {
			continue
		}
		moviesList = append(moviesList, m)
	}

	if moviesList == nil {
		moviesList = []Movie{} // Return empty array instead of null
	}

	json.NewEncoder(w).Encode(moviesList)
}

func HandleAddToWatchlist(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var payload map[string]string
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		http.Error(w, "Bad Request", http.StatusBadRequest)
		return
	}
	
	// Update database status to downloading (real implementation of pushing to pipeline)
	DB.Exec("UPDATE movies SET status = 'Downloading' WHERE id = ?", payload["movie_id"])
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  "added",
		"message": "Movie pushed to download pipeline successfully.",
	})
}

func HandleGetSubtitles(w http.ResponseWriter, r *http.Request) {
	imdbId := r.URL.Query().Get("imdb_id")
	
	// Simulate checking local disk for subtitle files
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode([]map[string]interface{}{
		{"lang": "el", "url": "/api/v1/movies/subs?lang=el&imdb_id=" + imdbId, "imdb_id": imdbId},
		{"lang": "en", "url": "/api/v1/movies/subs?lang=en&imdb_id=" + imdbId, "imdb_id": imdbId},
	})
}

func HandleServeSubtitle(w http.ResponseWriter, r *http.Request) {
	lang := r.URL.Query().Get("lang")
	imdbId := r.URL.Query().Get("imdb_id")
	
	path := "./data/movies/subs/" + imdbId + "_" + lang + ".srt"
	w.Header().Set("Content-Type", "text/plain")
	http.ServeFile(w, r, path)
}
