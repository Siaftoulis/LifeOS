package music

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"strconv"
	"time"
)

func HandleRecordHistory(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	var req struct {
		TrackID        string  `json:"track_id"`
		PositionMs     int64   `json:"position_ms"`
		DurationMs     int64   `json:"duration_ms"`
		CompletionRate float64 `json:"completion_rate"`
		Skipped        bool    `json:"skipped"`
		Source         string  `json:"source"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.TrackID == "" {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	id := "lh-" + strconv.FormatInt(time.Now().UnixNano(), 36)
	now := time.Now().UnixMilli()
	_, err := DB.Exec(`INSERT INTO listening_history (id, track_id, played_at, position_ms, duration_ms, completion_rate, skipped, source)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
		id, req.TrackID, now, req.PositionMs, req.DurationMs, req.CompletionRate, req.Skipped, req.Source)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Update track play count and last played
	DB.Exec("UPDATE music_tracks SET play_count = play_count + 1, last_played_at = ? WHERE id = ?", now, req.TrackID)

	json.NewEncoder(w).Encode(map[string]any{"id": id, "status": "recorded"})
}

func HandleGetHistory(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	limit := 200
	if l := r.URL.Query().Get("limit"); l != "" {
		if v, err := strconv.Atoi(l); err == nil {
			limit = v
		}
	}

	rows, err := DB.Query(`
		SELECT lh.id, lh.track_id, lh.played_at, lh.position_ms, lh.duration_ms, lh.completion_rate, lh.skipped, lh.source,
		       mt.title, mt.artist, mt.album, COALESCE(NULLIF(mt.thumbnail, ''), mt.thumbnail_url, '')
		FROM listening_history lh
		LEFT JOIN music_tracks mt ON mt.id = lh.track_id
		ORDER BY lh.played_at DESC
		LIMIT ?
	`, limit)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var items []HistoryItem
	for rows.Next() {
		var item HistoryItem
		var title, artist, album, thumb sql.NullString
		var durMs, posMs sql.NullInt64
		var compRate sql.NullFloat64
		var skipped int
		if err := rows.Scan(&item.ID, &item.TrackID, &item.PlayedAt, &posMs, &durMs, &compRate, &skipped, &item.Source,
			&title, &artist, &album, &thumb); err == nil {
			if posMs.Valid {
				item.PositionMs = posMs.Int64
			}
			if durMs.Valid {
				item.DurationMs = durMs.Int64
			}
			if compRate.Valid {
				item.CompletionRate = compRate.Float64
			}
			item.Skipped = skipped == 1
			item.Title = title.String
			item.Artist = artist.String
			item.Album = album.String
			item.ThumbnailURL = thumb.String
			items = append(items, item)
		}
	}
	if items == nil {
		items = []HistoryItem{}
	}
	json.NewEncoder(w).Encode(items)
}

func HandleGetStats(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	days := 30
	if d := r.URL.Query().Get("days"); d != "" {
		if v, err := strconv.Atoi(d); err == nil {
			days = v
		}
	}
	since := time.Now().AddDate(0, 0, -days).UnixMilli()

	var stats Stats
	DB.QueryRow(`
		SELECT COUNT(*), COUNT(DISTINCT track_id), COUNT(DISTINCT artist), COALESCE(SUM(duration_ms), 0)
		FROM listening_history
		WHERE played_at > ?
	`, since).Scan(&stats.TotalPlays, &stats.UniqueTracks, &stats.UniqueArtists, &stats.TotalMs)

	rows, _ := DB.Query(`
		SELECT artist, COUNT(*) as cnt FROM listening_history lh
		JOIN music_tracks mt ON mt.id = lh.track_id
		WHERE lh.played_at > ? AND mt.artist IS NOT NULL AND mt.artist != ''
		GROUP BY artist ORDER BY cnt DESC LIMIT 20
	`, since)
	for rows != nil && rows.Next() {
		var artist string
		rows.Scan(&artist)
		stats.TopArtists = append(stats.TopArtists, artist)
	}
	if rows != nil {
		rows.Close()
	}

	rows, _ = DB.Query(`
		SELECT genre, COUNT(*) as cnt FROM listening_history lh
		JOIN music_tracks mt ON mt.id = lh.track_id
		WHERE lh.played_at > ? AND mt.genre IS NOT NULL AND mt.genre != ''
		GROUP BY genre ORDER BY cnt DESC LIMIT 15
	`, since)
	for rows != nil && rows.Next() {
		var genre string
		rows.Scan(&genre)
		stats.TopGenres = append(stats.TopGenres, genre)
	}
	if rows != nil {
		rows.Close()
	}

	json.NewEncoder(w).Encode(stats)
}
