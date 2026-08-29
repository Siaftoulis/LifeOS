package music

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"strconv"
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
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	_, err := DB.Exec("UPDATE playlists SET name = COALESCE(NULLIF(?, ''), name), description = COALESCE(NULLIF(?, ''), description), cover_art_url = COALESCE(NULLIF(?, ''), cover_art_url), updated_at = ? WHERE id = ?",
		req.Name, req.Description, req.CoverArtURL, time.Now().UnixMilli(), id)
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
	rows, err := DB.Query(`
		SELECT mt.id, mt.title, mt.artist, mt.album, mt.album_artist, mt.track_number, mt.disc_number, mt.year, mt.genre,
		       mt.file_path, mt.lyrics_path, mt.thumbnail_url, mt.yt_dlp_id, mt.duration, mt.bitrate, mt.codec,
		       mt.replay_gain_track, mt.replay_gain_album, mt.play_count, mt.last_played_at, mt.added_at,
		       pt.position
		FROM playlist_tracks pt
		JOIN music_tracks mt ON mt.id = pt.track_id
		WHERE pt.playlist_id = ?
		ORDER BY pt.position
	`, id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var tracks []PlaylistTrack
	for rows.Next() {
		var t Track
		var albumArtist, genre, filePath, lyricsPath, thumbUrl, ytDlpId, codec sql.NullString
		var trackNum, discNum, year, bitrate sql.NullInt64
		var replayTrack, replayAlbum sql.NullFloat64
		var playCount sql.NullInt64
		var lastPlayed, addedAt sql.NullInt64
		var pos int
		if err := rows.Scan(&t.ID, &t.Title, &t.Artist, &t.Album, &albumArtist, &trackNum, &discNum, &year, &genre,
			&filePath, &lyricsPath, &thumbUrl, &ytDlpId, &t.Duration, &bitrate, &codec,
			&replayTrack, &replayAlbum, &playCount, &lastPlayed, &addedAt, &pos); err == nil {
			tracks = append(tracks, PlaylistTrack{Track: t, Position: pos})
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
		TrackID string `json:"track_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.TrackID == "" {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	var maxPos int
	DB.QueryRow("SELECT COALESCE(MAX(position), -1) + 1 FROM playlist_tracks WHERE playlist_id = ?", id).Scan(&maxPos)

	ptID := id + "-" + req.TrackID
	now := time.Now().UnixMilli()
	_, err := DB.Exec("INSERT OR IGNORE INTO playlist_tracks (id, playlist_id, track_id, position, added_at) VALUES (?, ?, ?, ?, ?)",
		ptID, id, req.TrackID, maxPos, now)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	DB.Exec(`UPDATE playlists SET 
		track_count = (SELECT COUNT(*) FROM playlist_tracks WHERE playlist_id = ?),
		total_duration = (SELECT COALESCE(SUM(mt.duration), 0) FROM playlist_tracks pt JOIN music_tracks mt ON mt.id = pt.track_id WHERE pt.playlist_id = ?),
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
