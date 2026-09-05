package music

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"net/url"
	"strings"
)

// maxSongSeconds keeps playlists/mixes out of results: a song is <= 12 min.
const maxSongSeconds = 720

type SearchResult struct {
	ID        string  `json:"id"`
	Title     string  `json:"title"`
	Artist    string  `json:"artist"`
	Duration  float64 `json:"duration"`
	Thumbnail string  `json:"thumbnail"`
}

type flatEntry struct {
	ID         string            `json:"id"`
	Title      string            `json:"title"`
	Uploader   string            `json:"uploader"`
	Duration   float64           `json:"duration"`
	Thumbnails []json.RawMessage `json:"thumbnails"`
}

type flatDump struct {
	Entries []flatEntry `json:"entries"`
}

func isDirectYouTubeURL(q string) bool {
	q = strings.TrimSpace(q)
	if q == "" {
		return false
	}
	u, err := url.Parse(q)
	if err != nil || u.Host == "" {
		return false
	}
	host := strings.ToLower(u.Host)
	if host != "youtube.com" && !strings.HasSuffix(host, ".youtube.com") &&
		host != "youtu.be" && !strings.HasSuffix(host, ".youtu.be") {
		return false
	}
	if strings.Contains(host, "youtu.be") {
		parts := strings.Split(strings.Trim(u.Path, "/"), "/")
		return len(parts) >= 1 && len(parts[0]) == 11
	}
	if u.Path == "/watch" && len(u.Query().Get("v")) == 11 {
		return true
	}
	parts := strings.Split(strings.Trim(u.Path, "/"), "/")
	if len(parts) >= 2 {
		first := strings.ToLower(parts[0])
		if (first == "shorts" || first == "embed" || first == "v") && len(parts[1]) == 11 {
			return true
		}
	}
	return false
}

func extractThumbnail(rawThumbs []json.RawMessage, id string) string {
	if len(rawThumbs) > 0 {
		var t struct {
			URL string `json:"url"`
		}
		if err := json.Unmarshal(rawThumbs[len(rawThumbs)-1], &t); err == nil && t.URL != "" {
			return t.URL
		} else if err := json.Unmarshal(rawThumbs[0], &t); err == nil && t.URL != "" {
			return t.URL
		}
	}
	return "https://i.ytimg.com/vi/" + id + "/hqdefault.jpg"
}

// HandleSearch runs `yt-dlp ytsearchN:<query>` (flat, no download) and returns
// the song-sized results. Supports both GET ?q= and POST {"query": "..."}.
func HandleSearch(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	var query string
	if r.Method == http.MethodGet {
		query = strings.TrimSpace(r.URL.Query().Get("q"))
		if query == "" {
			query = strings.TrimSpace(r.URL.Query().Get("query"))
		}
	} else if r.Method == http.MethodPost {
		var payload struct {
			Query string `json:"query"`
			Q     string `json:"q"`
		}
		if err := json.NewDecoder(r.Body).Decode(&payload); err == nil {
			query = strings.TrimSpace(payload.Query)
			if query == "" {
				query = strings.TrimSpace(payload.Q)
			}
		}
	} else {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	if query == "" {
		http.Error(w, "Missing query", http.StatusBadRequest)
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), defaultSearchTimeout)
	defer cancel()

	target := "ytsearch15:" + query
	if isDirectYouTubeURL(query) {
		target = query
	}

	args := []string{
		"--js-runtimes", jsRuntimesArg(),
		"--flat-playlist",
		"--dump-single-json",
		"--no-playlist",
		"--skip-download",
		"--no-warnings",
		"--no-check-certificates",
		"--default-search", "ytsearch",
		target,
	}

	out, err := ExecYtDlp(ctx, "search", query, args)
	if err != nil {
		http.Error(w, "Search failed", http.StatusBadGateway)
		return
	}

	results := make([]SearchResult, 0)
	var dump flatDump
	if err := json.Unmarshal(out, &dump); err == nil && len(dump.Entries) > 0 {
		for _, e := range dump.Entries {
			if e.ID == "" || e.Title == "" || e.Duration > maxSongSeconds {
				continue
			}
			results = append(results, SearchResult{
				ID:        e.ID,
				Title:     e.Title,
				Artist:    e.Uploader,
				Duration:  e.Duration,
				Thumbnail: extractThumbnail(e.Thumbnails, e.ID),
			})
		}
	} else {
		var single flatEntry
		if err := json.Unmarshal(out, &single); err == nil && single.ID != "" && single.Title != "" {
			if single.Duration <= maxSongSeconds {
				results = append(results, SearchResult{
					ID:        single.ID,
					Title:     single.Title,
					Artist:    single.Uploader,
					Duration:  single.Duration,
					Thumbnail: extractThumbnail(single.Thumbnails, single.ID),
				})
			}
		} else {
			log.Printf("music search: parse failed for %q: %v", query, err)
			http.Error(w, "Search failed", http.StatusBadGateway)
			return
		}
	}

	json.NewEncoder(w).Encode(results)
}
