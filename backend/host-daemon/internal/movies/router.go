package movies

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"lifeos/host-daemon/internal/auth/middleware"
	"lifeos/host-daemon/internal/bus"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/movies", HandleMovies)
	mux.HandleFunc("/api/v1/movies/search", HandleSearch)
	mux.HandleFunc("/api/v1/movies/{id}", HandleMovies)
	mux.HandleFunc("/api/v1/movies/watchlist", HandleWatchlist)
	mux.HandleFunc("/api/v1/movies/reviews", HandleReviews)
	mux.HandleFunc("/api/v1/movies/enrich", HandleEnrich)
	mux.HandleFunc("/api/v1/movies/subtitles", HandleGetSubtitles)
	mux.HandleFunc("/api/v1/movies/subs", HandleServeSubtitle)
}

const movieSelect = "SELECT m.id, m.imdb_id, m.title, m.director, m.release_year, m.color_hex, m.status, COALESCE((SELECT r.rating FROM movie_reviews r WHERE r.movie_id = m.id), 0), COALESCE(m.tmdb_id, 0), COALESCE(m.poster_path, ''), COALESCE(m.overview, ''), COALESCE(m.genres, ''), COALESCE(m.tmdb_rating, 0)"

func scanMovie(rows interface {
	Scan(dest ...any) error
}) (Movie, error) {
	var m Movie
	var posterPath string
	err := rows.Scan(&m.ID, &m.ImdbID, &m.Title, &m.Director, &m.Year, &m.ColorHex, &m.Status,
		&m.Rating, &m.TMDBID, &posterPath, &m.Overview, &m.Genres, &m.TMDBRating)
	m.PosterURL = tmdbPosterURL(posterPath)
	return m, err
}

var validStatuses = map[string]bool{
	"AVAILABLE": true, "DOWNLOADING": true, "WATCHED": true,
}

// WatchedEvent is the payload of the "movies:watched" bus event.
type WatchedEvent struct {
	MovieID string
	Title   string
	UserID  string
}

func updateMovieStatus(w http.ResponseWriter, r *http.Request) {
	var payload struct {
		Status string `json:"status"`
	}
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		http.Error(w, "Bad Request", http.StatusBadRequest)
		return
	}
	status := strings.ToUpper(strings.TrimSpace(payload.Status))
	if !validStatuses[status] {
		http.Error(w, "status must be one of AVAILABLE, DOWNLOADING, WATCHED", http.StatusBadRequest)
		return
	}
	res, err := DB.Exec("UPDATE movies SET status = ? WHERE id = ?", status, r.PathValue("id"))
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if n, _ := res.RowsAffected(); n == 0 {
		http.Error(w, "Movie not found", http.StatusNotFound)
		return
	}
	if status == "WATCHED" {
		var title string
		DB.QueryRow("SELECT title FROM movies WHERE id = ?", r.PathValue("id")).Scan(&title)
		userID, _ := r.Context().Value(middleware.UserContextKey).(string)
		bus.Publish(bus.Event{
			Topic:   "movies:watched",
			UserID:  userID,
			Payload: WatchedEvent{MovieID: r.PathValue("id"), Title: title, UserID: userID},
		})
	}
	fmt.Fprintf(w, `{"status":"%s"}`, status)
}

func HandleEnrich(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	if tmdbKey() == "" {
		http.Error(w, "TMDB_API_KEY not set on daemon", http.StatusServiceUnavailable)
		return
	}
	go enrichAllTMDB()
	w.Header().Set("Content-Type", "application/json")
	fmt.Fprintf(w, `{"status":"started"}`)
}

func HandleMovies(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if id := r.PathValue("id"); id != "" {
		switch r.Method {
		case http.MethodGet:
			getMovie(w, id)
		case http.MethodPut:
			updateMovieStatus(w, r)
		case http.MethodDelete:
			deleteMovie(w, id)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
		return
	}

	if r.Method == http.MethodPost {
		createMovie(w, r)
		return
	}

	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	query := movieSelect + " FROM movies m"
	var conds []string
	var args []any
	if q := strings.TrimSpace(r.URL.Query().Get("q")); q != "" {
		conds = append(conds, "m.title LIKE ?")
		args = append(args, "%"+q+"%")
	}
	if status := strings.TrimSpace(r.URL.Query().Get("status")); status != "" {
		conds = append(conds, "m.status = ?")
		args = append(args, strings.ToUpper(status))
	}
	if len(conds) > 0 {
		query += " WHERE " + strings.Join(conds, " AND ")
	}
	query += " ORDER BY m.title"

	rows, err := DB.Query(query, args...)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var moviesList []Movie
	for rows.Next() {
		if m, err := scanMovie(rows); err == nil {
			moviesList = append(moviesList, m)
		}
	}
	if moviesList == nil {
		moviesList = []Movie{}
	}
	json.NewEncoder(w).Encode(moviesList)
}

func getMovie(w http.ResponseWriter, id string) {
	row := DB.QueryRow(movieSelect+" FROM movies m WHERE m.id = ?", id)
	m, err := scanMovie(row)
	if err != nil {
		http.Error(w, "Movie not found", http.StatusNotFound)
		return
	}
	// Lazily enrich a single movie the first time it is read (the embed path);
	// the background pass covers the rest.
	if m.TMDBID == 0 && m.ImdbID != "" && tmdbKey() != "" {
		if err := enrichTMDBMovie(id, m.ImdbID); err == nil {
			row = DB.QueryRow(movieSelect+" FROM movies m WHERE m.id = ?", id)
			if m, err = scanMovie(row); err != nil {
				http.Error(w, "Movie not found", http.StatusNotFound)
				return
			}
		}
	}
	json.NewEncoder(w).Encode(m)
}

func HandleWatchlist(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	switch r.Method {
	case http.MethodGet:
		rows, err := DB.Query(`
			SELECT w.id, w.movie_id, w.priority, w.added_at, m.title, m.imdb_id, m.status
			FROM movie_watchlist w JOIN movies m ON m.id = w.movie_id
			ORDER BY w.priority DESC, w.added_at DESC`)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		defer rows.Close()

		var items []map[string]any
		for rows.Next() {
			var id, movieID, title, imdbID, status string
			var priority int
			var addedAt int64
			if err := rows.Scan(&id, &movieID, &priority, &addedAt, &title, &imdbID, &status); err == nil {
				items = append(items, map[string]any{
					"id": id, "movie_id": movieID, "priority": priority,
					"added_at": addedAt, "title": title, "imdb_id": imdbID, "status": status,
				})
			}
		}
		if items == nil {
			items = []map[string]any{}
		}
		json.NewEncoder(w).Encode(items)

	case http.MethodPost:
		var payload map[string]string
		if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
			http.Error(w, "Bad Request", http.StatusBadRequest)
			return
		}
		movieID := payload["movie_id"]
		if movieID == "" {
			http.Error(w, "movie_id required", http.StatusBadRequest)
			return
		}
		// ponytail: one watchlist entry per movie — id IS the movie_id, dedupe by ON CONFLICT.
		_, err := DB.Exec(`
			INSERT INTO movie_watchlist (id, movie_id, added_at) VALUES (?, ?, ?)
			ON CONFLICT(id) DO UPDATE SET priority = priority + 1`,
			movieID, movieID, time.Now().Unix())
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		DB.Exec("UPDATE movies SET status = 'Downloading' WHERE id = ?", movieID)

		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  "added",
			"message": "Movie pushed to download pipeline successfully.",
		})

	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func HandleReviews(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	switch r.Method {
	case http.MethodGet:
		movieID := r.URL.Query().Get("movie_id")
		if movieID == "" {
			http.Error(w, "movie_id required", http.StatusBadRequest)
			return
		}
		var rating float64
		var comment string
		err := DB.QueryRow("SELECT rating, COALESCE(comment, '') FROM movie_reviews WHERE movie_id = ?", movieID).Scan(&rating, &comment)
		if err != nil {
			json.NewEncoder(w).Encode(map[string]any{"movie_id": movieID, "rating": 0.0, "comment": ""})
			return
		}
		json.NewEncoder(w).Encode(map[string]any{"movie_id": movieID, "rating": rating, "comment": comment})

	case http.MethodPost:
		var payload struct {
			MovieID string  `json:"movie_id"`
			Rating  float64 `json:"rating"`
			Comment string  `json:"comment"`
		}
		if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
			http.Error(w, "Bad Request", http.StatusBadRequest)
			return
		}
		if payload.MovieID == "" {
			http.Error(w, "movie_id required", http.StatusBadRequest)
			return
		}
		if payload.Rating < 0 || payload.Rating > 10 {
			http.Error(w, "rating must be 0-10", http.StatusBadRequest)
			return
		}
		// ponytail: one review per movie — id IS the movie_id, upsert keeps no duplicates.
		_, err := DB.Exec(`
			INSERT INTO movie_reviews (id, movie_id, rating, comment) VALUES (?, ?, ?, ?)
			ON CONFLICT(id) DO UPDATE SET rating = excluded.rating, comment = excluded.comment`,
			payload.MovieID, payload.MovieID, payload.Rating, payload.Comment)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		DB.Exec("UPDATE movies SET status = 'WATCHED' WHERE id = ?", payload.MovieID)
		fmt.Fprintf(w, `{"status":"saved","movie_id":"%s"}`, payload.MovieID)

	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
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

func HandleSearch(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	q := strings.TrimSpace(r.URL.Query().Get("q"))
	if q == "" {
		json.NewEncoder(w).Encode([]Movie{})
		return
	}

	results, err := searchTMDB(q)
	if err == nil && len(results) > 0 {
		json.NewEncoder(w).Encode(results)
		return
	}

	// Fallback to local DB search
	query := movieSelect + " FROM movies m WHERE m.title LIKE ? ORDER BY m.title"
	rows, err := DB.Query(query, "%"+q+"%")
	if err != nil {
		json.NewEncoder(w).Encode([]Movie{})
		return
	}
	defer rows.Close()

	var moviesList []Movie
	for rows.Next() {
		if m, err := scanMovie(rows); err == nil {
			moviesList = append(moviesList, m)
		}
	}
	if moviesList == nil {
		moviesList = []Movie{}
	}
	json.NewEncoder(w).Encode(moviesList)
}

func createMovie(w http.ResponseWriter, r *http.Request) {
	var m Movie
	if err := json.NewDecoder(r.Body).Decode(&m); err != nil {
		http.Error(w, "Bad Request", http.StatusBadRequest)
		return
	}
	if m.ID == "" {
		m.ID = fmt.Sprintf("mov_%d", time.Now().UnixNano())
	}
	if m.Status == "" {
		m.Status = "AVAILABLE"
	}
	posterPath := m.PosterURL
	if strings.Contains(posterPath, "https://image.tmdb.org/t/p/w500") {
		posterPath = strings.TrimPrefix(posterPath, "https://image.tmdb.org/t/p/w500")
	}

	_, err := DB.Exec(`
		INSERT INTO movies (id, imdb_id, title, director, release_year, color_hex, status, tmdb_id, poster_path, overview, genres, tmdb_rating)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(id) DO UPDATE SET
			title = excluded.title,
			director = excluded.director,
			release_year = excluded.release_year,
			color_hex = excluded.color_hex,
			status = excluded.status,
			tmdb_id = excluded.tmdb_id,
			poster_path = excluded.poster_path,
			overview = excluded.overview,
			genres = excluded.genres,
			tmdb_rating = excluded.tmdb_rating`,
		m.ID, m.ImdbID, m.Title, m.Director, m.Year, m.ColorHex, m.Status,
		m.TMDBID, posterPath, m.Overview, m.Genres, m.TMDBRating)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(m)
}

func deleteMovie(w http.ResponseWriter, id string) {
	DB.Exec("DELETE FROM movie_reviews WHERE movie_id = ?", id)
	DB.Exec("DELETE FROM watchlist WHERE movie_id = ?", id)
	res, err := DB.Exec("DELETE FROM movies WHERE id = ?", id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if n, _ := res.RowsAffected(); n == 0 {
		http.Error(w, "Movie not found", http.StatusNotFound)
		return
	}
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, `{"status":"deleted","id":"%s"}`, id)
}

