package music

import (
	"encoding/json"
	"io"
	"net/http"
	"net/url"
	"regexp"
	"strconv"
	"strings"
)

type LyricLine struct {
	Time float64 `json:"time"` // seconds; -1 = unsynced plain lyrics
	Text string  `json:"text"`
}

var lrcTimeRe = regexp.MustCompile(`\[(\d+):(\d+(?:\.\d+)?)\]`)

// parseLRC converts the standard [mm:ss.xx]text format into LyricLines,
// taking the first timestamp of multi-timestamp lines ([00:01][00:05]text).
func parseLRC(lrc string) []LyricLine {
	var lines []LyricLine
	for _, raw := range strings.Split(lrc, "\n") {
		raw = strings.TrimSpace(raw)
		m := lrcTimeRe.FindStringSubmatch(raw)
		if m == nil {
			continue
		}
		min, _ := strconv.Atoi(m[1])
		sec, _ := strconv.ParseFloat(m[2], 64)
		text := strings.TrimSpace(lrcTimeRe.ReplaceAllString(raw, ""))
		if text == "" {
			continue
		}
		lines = append(lines, LyricLine{Time: float64(min)*60 + sec, Text: text})
	}
	return lines
}

// HandleGetLyrics fetches synced lyrics from LRCLIB (free, no key) for the
// given title/artist and returns timed lines.
func HandleGetLyrics(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	title := strings.TrimSpace(r.URL.Query().Get("title"))
	artist := strings.TrimSpace(r.URL.Query().Get("artist"))
	if title == "" {
		http.Error(w, "Missing title", http.StatusBadRequest)
		return
	}

	q := url.Values{}
	q.Set("track_name", title)
	q.Set("synced", "true")
	if artist != "" {
		q.Set("artist_name", artist)
	}
	res, err := http.Get("https://lrclib.net/api/search?" + q.Encode())
	if err != nil {
		http.Error(w, "Lyrics service unreachable", http.StatusBadGateway)
		return
	}
	defer res.Body.Close()
	body, _ := io.ReadAll(res.Body)

	var hits []struct {
		Instrumental  bool   `json:"instrumental"`
		SyncedLyrics  string `json:"syncedLyrics"`
		PlainLyrics   string `json:"plainLyrics"`
		TrackName     string `json:"trackName"`
		ArtistName    string `json:"artistName"`
	}
	if err := json.Unmarshal(body, &hits); err != nil {
		http.Error(w, "Lyrics parse failed", http.StatusBadGateway)
		return
	}

	for _, h := range hits {
		if h.Instrumental {
			continue
		}
		if h.SyncedLyrics != "" {
			json.NewEncoder(w).Encode(parseLRC(h.SyncedLyrics))
			return
		}
		if h.PlainLyrics != "" {
			lines := make([]LyricLine, 0)
			for _, l := range strings.Split(h.PlainLyrics, "\n") {
				if t := strings.TrimSpace(l); t != "" {
					lines = append(lines, LyricLine{Time: -1, Text: t})
				}
			}
			json.NewEncoder(w).Encode(lines)
			return
		}
	}
	json.NewEncoder(w).Encode([]LyricLine{})
}