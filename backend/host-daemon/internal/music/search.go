package music

import (
	"encoding/json"
	"log"
	"net/http"
	"os/exec"
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
	ID        string         `json:"id"`
	Title     string         `json:"title"`
	Uploader  string         `json:"uploader"`
	Duration  float64        `json:"duration"`
	Thumbnails []json.RawMessage `json:"thumbnails"`
}

type flatDump struct {
	Entries []flatEntry `json:"entries"`
}

// HandleSearch runs `yt-dlp ytsearchN:<query>` (flat, no download) and returns
// the song-sized results. Supports both GET ?q= and POST {"query": "..."}.
func HandleSearch(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
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

	out, err := exec.Command("yt-dlp",
		"--flat-playlist",
		"--dump-single-json",
		"--no-playlist",
		"--skip-download",
		"--no-warnings",
		"--no-check-certificates",
		"--default-search", "ytsearch",
		"ytsearch15:"+query,
	).Output()
	if err != nil {
		log.Printf("music search: yt-dlp failed for %q: %v", query, err)
		http.Error(w, "Search failed", http.StatusBadGateway)
		return
	}

	var dump flatDump
	if err := json.Unmarshal(out, &dump); err != nil {
		log.Printf("music search: parse failed for %q: %v", query, err)
		http.Error(w, "Search failed", http.StatusBadGateway)
		return
	}

	results := make([]SearchResult, 0, len(dump.Entries))
	for _, e := range dump.Entries {
		if e.ID == "" || e.Title == "" {
			continue
		}
		if e.Duration > maxSongSeconds {
			continue
		}
		thumb := ""
		if len(e.Thumbnails) > 0 {
			var t struct {
				URL string `json:"url"`
			}
			if err := json.Unmarshal(e.Thumbnails[len(e.Thumbnails)-1], &t); err == nil && t.URL != "" {
				thumb = t.URL
			} else if err := json.Unmarshal(e.Thumbnails[0], &t); err == nil {
				thumb = t.URL
			}
		}
		if thumb == "" {
			thumb = "https://i.ytimg.com/vi/" + e.ID + "/hqdefault.jpg"
		}
		results = append(results, SearchResult{
			ID:        e.ID,
			Title:     e.Title,
			Artist:    e.Uploader,
			Duration:  e.Duration,
			Thumbnail: thumb,
		})
	}
	json.NewEncoder(w).Encode(results)
}