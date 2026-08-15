package movies

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"
)

const tmdbBase = "https://api.themoviedb.org/3"

type tmdbFindResponse struct {
	MovieResults []tmdbMovie `json:"movie_results"`
}

type tmdbMovie struct {
	ID          int64  `json:"id"`
	PosterPath  string `json:"poster_path"`
	Overview    string `json:"overview"`
	Genres      []struct{ Name string } `json:"genres"`
	VoteAverage float64 `json:"vote_average"`
}

func tmdbKey() string {
	return os.Getenv("TMDB_API_KEY")
}

func tmdbPosterURL(path string) string {
	if path == "" {
		return ""
	}
	return "https://image.tmdb.org/t/p/w500" + path
}

// enrichAllTMDB fills TMDb metadata for every movie missing it. No-op when
// TMDB_API_KEY is unset (offline / no key: everything still works).
func enrichAllTMDB() {
	if tmdbKey() == "" {
		return
	}
	rows, err := DB.Query("SELECT id, imdb_id FROM movies WHERE (tmdb_id IS NULL OR tmdb_id = 0) AND imdb_id != ''")
	if err != nil {
		log.Printf("TMDB: query failed: %v", err)
		return
	}
	defer rows.Close()

	for rows.Next() {
		var id, imdb string
		if err := rows.Scan(&id, &imdb); err == nil {
			if err := enrichTMDBMovie(id, imdb); err != nil {
				log.Printf("TMDB: %v", err)
			}
		}
	}
}

// enrichTMDBMovie looks up one movie by imdb_id and caches the result.
func enrichTMDBMovie(id, imdbID string) error {
	if imdbID == "" {
		return nil
	}
	if tmdbKey() == "" {
		return fmt.Errorf("TMDB_API_KEY not set")
	}

	url := fmt.Sprintf("%s/find/%s?external_source=imdb_id&language=en", tmdbBase, imdbID)
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+tmdbKey())

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("tmdb find %s: %v", imdbID, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("tmdb find %s: status %d", imdbID, resp.StatusCode)
	}

	var find tmdbFindResponse
	if err := json.NewDecoder(resp.Body).Decode(&find); err != nil {
		return err
	}
	if len(find.MovieResults) == 0 {
		return fmt.Errorf("tmdb find %s: no results", imdbID)
	}

	m := find.MovieResults[0]
	genres := make([]string, 0, len(m.Genres))
	for _, g := range m.Genres {
		genres = append(genres, g.Name)
	}

	_, err = DB.Exec(`
		UPDATE movies
		SET tmdb_id = ?, poster_path = ?, overview = ?, genres = ?, tmdb_rating = ?
		WHERE id = ?`,
		m.ID, m.PosterPath, m.Overview, strings.Join(genres, ", "), m.VoteAverage, id)
	return err
}
