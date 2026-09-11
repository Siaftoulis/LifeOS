package music

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
	"time"
)

func HandleGetPlaylists(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	isSmart := r.URL.Query().Get("smart")
	query := "SELECT id, name, description, cover_art_url, is_smart, smart_type, smart_config, track_count, total_duration, created_at, updated_at FROM playlists"
	var args []any
	if isSmart == "true" {
		query += " WHERE is_smart = 1"
	} else if isSmart == "false" {
		query += " WHERE is_smart = 0"
	}
	query += " ORDER BY updated_at DESC"

	rows, err := DB.Query(query, args...)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var playlists []Playlist
	for rows.Next() {
		var p Playlist
		var desc, coverArt, smartType, smartConfig sql.NullString
		if err := rows.Scan(&p.ID, &p.Name, &desc, &coverArt, &p.IsSmart, &smartType, &smartConfig, &p.TrackCount, &p.TotalDuration, &p.CreatedAt, &p.UpdatedAt); err == nil {
			p.Description = desc.String
			p.CoverArtURL = coverArt.String
			p.SmartType = smartType.String
			p.SmartConfig = smartConfig.String
			if p.IsSmart {
				p.TrackCount, p.TotalDuration = getSmartPlaylistStats(p.SmartType, p.SmartConfig)
			}
			playlists = append(playlists, p)
		}
	}
	if playlists == nil {
		playlists = []Playlist{}
	}
	json.NewEncoder(w).Encode(playlists)
}

func HandleCreatePlaylist(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	var req struct {
		Name        string `json:"name"`
		Description string `json:"description"`
		IsSmart     bool   `json:"is_smart"`
		SmartType   string `json:"smart_type"`
		SmartConfig string `json:"smart_config"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Name == "" {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	id := "pl-" + strconv.FormatInt(time.Now().UnixNano(), 36)
	now := time.Now().UnixMilli()
	_, err := DB.Exec(`INSERT INTO playlists (id, name, description, is_smart, smart_type, smart_config, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
		id, req.Name, req.Description, req.IsSmart, req.SmartType, req.SmartConfig, now, now)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	json.NewEncoder(w).Encode(map[string]any{"id": id, "status": "created"})
}

func HandleGetPlaylist(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	id := r.PathValue("id")
	var p Playlist
	var desc, coverArt, smartType, smartConfig sql.NullString
	err := DB.QueryRow("SELECT id, name, description, cover_art_url, is_smart, smart_type, smart_config, track_count, total_duration, created_at, updated_at FROM playlists WHERE id = ?", id).
		Scan(&p.ID, &p.Name, &desc, &coverArt, &p.IsSmart, &smartType, &smartConfig, &p.TrackCount, &p.TotalDuration, &p.CreatedAt, &p.UpdatedAt)
	if err == sql.ErrNoRows {
		http.Error(w, "Playlist not found", http.StatusNotFound)
		return
	}
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	p.Description = desc.String
	p.CoverArtURL = coverArt.String
	p.SmartType = smartType.String
	p.SmartConfig = smartConfig.String
	if p.IsSmart {
		p.TrackCount, p.TotalDuration = getSmartPlaylistStats(p.SmartType, p.SmartConfig)
	}
	json.NewEncoder(w).Encode(p)
}

func HandleUpdatePlaylist(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	id := r.PathValue("id")
	var req struct {
		Name        string `json:"name"`
		Description string `json:"description"`
		CoverArtURL string `json:"cover_art_url"`
		IsSmart     *bool  `json:"is_smart"`
		SmartType   string `json:"smart_type"`
		SmartConfig string `json:"smart_config"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	query := `UPDATE playlists SET 
		name = COALESCE(NULLIF(?, ''), name), 
		description = COALESCE(NULLIF(?, ''), description), 
		cover_art_url = COALESCE(NULLIF(?, ''), cover_art_url),
		smart_type = CASE WHEN ? != '' THEN ? ELSE smart_type END,
		smart_config = CASE WHEN ? != '' THEN ? ELSE smart_config END,`
	var args = []any{req.Name, req.Description, req.CoverArtURL, req.SmartType, req.SmartType, req.SmartConfig, req.SmartConfig}
	if req.IsSmart != nil {
		query += " is_smart = ?, "
		args = append(args, *req.IsSmart)
	}
	query += " updated_at = ? WHERE id = ?"
	args = append(args, time.Now().UnixMilli(), id)

	_, err := DB.Exec(query, args...)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	json.NewEncoder(w).Encode(map[string]any{"status": "updated", "id": id})
}

func HandleDeletePlaylist(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	id := r.PathValue("id")
	if id == "" {
		http.Error(w, "Missing playlist id", http.StatusBadRequest)
		return
	}

	_, err := DB.Exec("DELETE FROM playlists WHERE id = ?", id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	json.NewEncoder(w).Encode(map[string]any{"status": "deleted", "id": id})
}

func HandleGetPlaylistTracks(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	id := r.PathValue("id")

	var isSmart bool
	var smartType, smartConfig string
	DB.QueryRow("SELECT is_smart, COALESCE(smart_type, ''), COALESCE(smart_config, '') FROM playlists WHERE id = ?", id).
		Scan(&isSmart, &smartType, &smartConfig)

	var tracks []PlaylistTrack
	if isSmart {
		smartQ, smartArgs := buildSmartPlaylistQuery(smartType, smartConfig, false)
		rows, err := DB.Query(smartQ, smartArgs...)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		defer rows.Close()

		pos := 0
		for rows.Next() {
			var t Track
			var albumArtist, genre, filePath, lyricsPath, thumb, ytDlpId, codec sql.NullString
			var trackNum, discNum, year, bitrate sql.NullInt64
			var replayTrack, replayAlbum sql.NullFloat64
			var playCount sql.NullInt64
			var lastPlayed, addedAt sql.NullInt64
			if err := rows.Scan(&t.ID, &t.Title, &t.Artist, &t.Album, &albumArtist, &trackNum, &discNum, &year, &genre,
				&filePath, &lyricsPath, &thumb, &ytDlpId, &t.Duration, &bitrate, &codec,
				&replayTrack, &replayAlbum, &playCount, &lastPlayed, &addedAt); err == nil {
				t.FilePath = filePath.String
				t.Thumbnail = thumb.String
				t.ThumbnailURL = thumb.String
				tracks = append(tracks, PlaylistTrack{Track: t, Position: pos})
				pos++
			}
		}
	} else {
		rows, err := DB.Query(`
			SELECT COALESCE(mt.id, pt.track_id),
			       COALESCE(mt.title, 'Unknown Track'),
			       COALESCE(mt.artist, 'Unknown Artist'),
			       COALESCE(mt.album, ''),
			       COALESCE(mt.album_artist, ''),
			       mt.track_number, mt.disc_number, mt.year, mt.genre,
			       COALESCE(mt.file_path, ''),
			       COALESCE(mt.lyrics_path, ''),
			       COALESCE(NULLIF(mt.thumbnail, ''), mt.thumbnail_url, ''),
			       COALESCE(mt.yt_dlp_id, ''),
			       COALESCE(mt.duration, 0),
			       mt.bitrate, mt.codec,
			       mt.replay_gain_track, mt.replay_gain_album, mt.play_count, mt.last_played_at, mt.added_at,
			       pt.position
			FROM playlist_tracks pt
			LEFT JOIN music_tracks mt ON mt.id = pt.track_id
			WHERE pt.playlist_id = ?
			ORDER BY pt.position
		`, id)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		defer rows.Close()

		for rows.Next() {
			var t Track
			var albumArtist, genre, filePath, lyricsPath, thumb, ytDlpId, codec sql.NullString
			var trackNum, discNum, year, bitrate sql.NullInt64
			var replayTrack, replayAlbum sql.NullFloat64
			var playCount sql.NullInt64
			var lastPlayed, addedAt sql.NullInt64
			var pos int
			if err := rows.Scan(&t.ID, &t.Title, &t.Artist, &t.Album, &albumArtist, &trackNum, &discNum, &year, &genre,
				&filePath, &lyricsPath, &thumb, &ytDlpId, &t.Duration, &bitrate, &codec,
				&replayTrack, &replayAlbum, &playCount, &lastPlayed, &addedAt, &pos); err == nil {
				t.FilePath = filePath.String
				t.Thumbnail = thumb.String
				t.ThumbnailURL = thumb.String
				tracks = append(tracks, PlaylistTrack{Track: t, Position: pos})
			}
		}
	}

	if tracks == nil {
		tracks = []PlaylistTrack{}
	}
	json.NewEncoder(w).Encode(tracks)
}

func HandleAddPlaylistTrack(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	id := r.PathValue("id")
	var req struct {
		TrackID   string  `json:"track_id"`
		Title     string  `json:"title,omitempty"`
		Artist    string  `json:"artist,omitempty"`
		Album     string  `json:"album,omitempty"`
		Thumbnail string  `json:"thumbnail,omitempty"`
		FilePath  string  `json:"file_path,omitempty"`
		Duration  float64 `json:"duration,omitempty"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.TrackID == "" {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	now := time.Now().UnixMilli()
	if req.Title != "" || req.FilePath != "" {
		DB.Exec(`INSERT INTO music_tracks (id, title, artist, album, thumbnail, file_path, duration, added_at, updated_at)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
			ON CONFLICT(id) DO UPDATE SET
				title = CASE WHEN excluded.title != '' THEN excluded.title ELSE music_tracks.title END,
				artist = CASE WHEN excluded.artist != '' THEN excluded.artist ELSE music_tracks.artist END,
				album = CASE WHEN excluded.album != '' THEN excluded.album ELSE music_tracks.album END,
				thumbnail = CASE WHEN excluded.thumbnail != '' THEN excluded.thumbnail ELSE music_tracks.thumbnail END,
				file_path = CASE WHEN excluded.file_path != '' THEN excluded.file_path ELSE music_tracks.file_path END,
				duration = CASE WHEN excluded.duration > 0 THEN excluded.duration ELSE music_tracks.duration END,
				updated_at = excluded.updated_at`,
			req.TrackID, req.Title, req.Artist, req.Album, req.Thumbnail, req.FilePath, req.Duration, now, now)
	}

	var maxPos int
	DB.QueryRow("SELECT COALESCE(MAX(position), -1) + 1 FROM playlist_tracks WHERE playlist_id = ?", id).Scan(&maxPos)

	ptID := id + "-" + req.TrackID
	_, err := DB.Exec("INSERT OR IGNORE INTO playlist_tracks (id, playlist_id, track_id, position, added_at) VALUES (?, ?, ?, ?, ?)",
		ptID, id, req.TrackID, maxPos, now)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	DB.Exec(`UPDATE playlists SET 
		track_count = (SELECT COUNT(*) FROM playlist_tracks WHERE playlist_id = ?),
		total_duration = (SELECT COALESCE(SUM(COALESCE(mt.duration, 0)), 0) FROM playlist_tracks pt LEFT JOIN music_tracks mt ON mt.id = pt.track_id WHERE pt.playlist_id = ?),
		updated_at = ? WHERE id = ?`, id, id, now, id)

	json.NewEncoder(w).Encode(map[string]any{"status": "added", "playlist_id": id, "track_id": req.TrackID})
}

func HandleRemovePlaylistTrack(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	id := r.PathValue("id")
	trackID := r.PathValue("trackId")
	if id == "" || trackID == "" {
		http.Error(w, "Missing playlist or track id", http.StatusBadRequest)
		return
	}

	_, err := DB.Exec("DELETE FROM playlist_tracks WHERE playlist_id = ? AND track_id = ?", id, trackID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	now := time.Now().UnixMilli()
	DB.Exec(`UPDATE playlists SET 
		track_count = (SELECT COUNT(*) FROM playlist_tracks WHERE playlist_id = ?),
		total_duration = (SELECT COALESCE(SUM(mt.duration), 0) FROM playlist_tracks pt JOIN music_tracks mt ON mt.id = pt.track_id WHERE pt.playlist_id = ?),
		updated_at = ? WHERE id = ?`, id, id, now, id)

	json.NewEncoder(w).Encode(map[string]any{"status": "removed", "playlist_id": id, "track_id": trackID})
}

func HandleReorderPlaylistTracks(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	id := r.PathValue("id")
	var req struct {
		TrackID     string `json:"track_id"`
		NewPosition int    `json:"new_position"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.TrackID == "" {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	var oldPos int
	err := DB.QueryRow("SELECT position FROM playlist_tracks WHERE playlist_id = ? AND track_id = ?", id, req.TrackID).Scan(&oldPos)
	if err == sql.ErrNoRows {
		http.Error(w, "Track not in playlist", http.StatusNotFound)
		return
	}
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if oldPos == req.NewPosition {
		json.NewEncoder(w).Encode(map[string]any{"status": "unchanged"})
		return
	}

	tx, _ := DB.Begin()
	if oldPos < req.NewPosition {
		tx.Exec("UPDATE playlist_tracks SET position = position - 1 WHERE playlist_id = ? AND position > ? AND position <= ?", id, oldPos, req.NewPosition)
	} else {
		tx.Exec("UPDATE playlist_tracks SET position = position + 1 WHERE playlist_id = ? AND position >= ? AND position < ?", id, req.NewPosition, oldPos)
	}
	tx.Exec("UPDATE playlist_tracks SET position = ? WHERE playlist_id = ? AND track_id = ?", req.NewPosition, id, req.TrackID)
	tx.Commit()

	json.NewEncoder(w).Encode(map[string]any{"status": "reordered", "track_id": req.TrackID, "new_position": req.NewPosition})
}

func getSmartPlaylistStats(smartType, smartConfig string) (int, int64) {
	if DB == nil {
		return 0, 0
	}
	query, args := buildSmartPlaylistQuery(smartType, smartConfig, true)
	if query == "" {
		return 0, 0
	}
	var count int
	var duration float64
	DB.QueryRow(query, args...).Scan(&count, &duration)
	return count, int64(duration)
}

func buildSmartPlaylistQuery(smartType, smartConfig string, isStats bool) (string, []any) {
	cols := `mt.id, mt.title, mt.artist, mt.album, mt.album_artist, mt.track_number, mt.disc_number, mt.year, mt.genre,
		COALESCE(mt.file_path, ''), COALESCE(mt.lyrics_path, ''), COALESCE(NULLIF(mt.thumbnail, ''), mt.thumbnail_url, ''),
		COALESCE(mt.yt_dlp_id, ''), COALESCE(mt.duration, 0), mt.bitrate, mt.codec,
		mt.replay_gain_track, mt.replay_gain_album, mt.play_count, mt.last_played_at, mt.added_at`
	if isStats {
		cols = `COUNT(*), COALESCE(SUM(mt.duration), 0)`
	}

	var q string
	var args []any

	switch strings.ToLower(smartType) {
	case "genre":
		q = "SELECT " + cols + " FROM music_tracks mt WHERE LOWER(mt.genre) LIKE ? "
		args = append(args, "%"+strings.ToLower(strings.TrimSpace(smartConfig))+"%")
		if !isStats {
			q += "ORDER BY mt.artist, mt.album, mt.track_number, mt.title"
		}
	case "decade":
		start, end := parseDecadeOrYears(smartConfig)
		q = "SELECT " + cols + " FROM music_tracks mt WHERE mt.year >= ? AND mt.year <= ? "
		args = append(args, start, end)
		if !isStats {
			q += "ORDER BY mt.year DESC, mt.artist, mt.title"
		}
	case "year":
		y, _ := strconv.Atoi(strings.TrimSpace(smartConfig))
		q = "SELECT " + cols + " FROM music_tracks mt WHERE mt.year = ? "
		args = append(args, y)
		if !isStats {
			q += "ORDER BY mt.artist, mt.album, mt.title"
		}
	case "folder":
		cleanCfg := strings.ToLower(strings.TrimSpace(smartConfig))
		cleanCfg = strings.ReplaceAll(cleanCfg, "/", "\\")
		q = "SELECT " + cols + " FROM music_tracks mt WHERE LOWER(REPLACE(mt.file_path, '/', '\\')) LIKE ? "
		args = append(args, "%"+cleanCfg+"%")
		if !isStats {
			q += "ORDER BY mt.file_path"
		}
	case "recently_added":
		q = "SELECT " + cols + " FROM music_tracks mt "
		if !isStats {
			q += "ORDER BY mt.added_at DESC LIMIT 100"
		}
	case "most_played":
		q = "SELECT " + cols + " FROM music_tracks mt WHERE mt.play_count > 0 "
		if !isStats {
			q += "ORDER BY mt.play_count DESC, mt.title LIMIT 100"
		}
	default:
		cfg := strings.ToLower(strings.TrimSpace(smartConfig))
		if cfg != "" {
			q = "SELECT " + cols + " FROM music_tracks mt WHERE LOWER(mt.genre) LIKE ? OR LOWER(mt.file_path) LIKE ? OR LOWER(mt.title) LIKE ? "
			args = append(args, "%"+cfg+"%", "%"+cfg+"%", "%"+cfg+"%")
			if !isStats {
				q += "ORDER BY mt.artist, mt.title LIMIT 100"
			}
		} else {
			q = "SELECT " + cols + " FROM music_tracks mt "
			if !isStats {
				q += "ORDER BY mt.title LIMIT 100"
			}
		}
	}
	return q, args
}

func parseDecadeOrYears(input string) (int, int) {
	s := strings.ToLower(strings.TrimSpace(input))
	switch {
	case strings.Contains(s, "60"):
		return 1960, 1969
	case strings.Contains(s, "70"):
		return 1970, 1979
	case strings.Contains(s, "80"):
		return 1980, 1989
	case strings.Contains(s, "90"):
		return 1990, 1999
	case strings.Contains(s, "2000") || s == "00s":
		return 2000, 2009
	case strings.Contains(s, "2010") || s == "10s":
		return 2010, 2019
	case strings.Contains(s, "2020") || s == "20s":
		return 2020, 2029
	}
	if parts := strings.Split(s, "-"); len(parts) == 2 {
		y1, err1 := strconv.Atoi(strings.TrimSpace(parts[0]))
		y2, err2 := strconv.Atoi(strings.TrimSpace(parts[1]))
		if err1 == nil && err2 == nil {
			return y1, y2
		}
	}
	if y, err := strconv.Atoi(s); err == nil {
		return y, y + 9
	}
	return 1980, 1989
}
