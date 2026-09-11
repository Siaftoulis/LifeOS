package music

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"time"
)

func HandleGetLiked(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	rows, err := DB.Query(`
		SELECT COALESCE(mt.id, ls.id),
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
		       mt.replay_gain_track, mt.replay_gain_album, mt.play_count, mt.last_played_at, mt.added_at
		FROM liked_songs ls
		LEFT JOIN music_tracks mt ON mt.id = ls.id
		ORDER BY ls.liked_at DESC
	`)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var tracks []Track
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
			tracks = append(tracks, t)
		}
	}
	if tracks == nil {
		tracks = []Track{}
	}
	json.NewEncoder(w).Encode(tracks)
}

func HandleToggleLiked(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

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

	var exists int
	err := DB.QueryRow("SELECT 1 FROM liked_songs WHERE id = ?", req.TrackID).Scan(&exists)
	if err == sql.ErrNoRows {
		_, err = DB.Exec("INSERT INTO liked_songs (id, liked_at) VALUES (?, ?)", req.TrackID, now)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		art, gen := FindTrackArtistAndGenre(r.Context(), req.TrackID)
		UpdateUserAffinity(r.Context(), art, gen, 1.0, false, true)
		json.NewEncoder(w).Encode(map[string]any{"status": "liked", "track_id": req.TrackID})
		return
	}
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	_, err = DB.Exec("DELETE FROM liked_songs WHERE id = ?", req.TrackID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	art, gen := FindTrackArtistAndGenre(r.Context(), req.TrackID)
	UpdateUserAffinity(r.Context(), art, gen, 0.0, false, false)
	json.NewEncoder(w).Encode(map[string]any{"status": "unliked", "track_id": req.TrackID})
}

func HandleRemoveLiked(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	id := r.PathValue("id")
	if id == "" {
		http.Error(w, "Missing track id", http.StatusBadRequest)
		return
	}

	_, err := DB.Exec("DELETE FROM liked_songs WHERE id = ?", id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	json.NewEncoder(w).Encode(map[string]any{"status": "removed", "track_id": id})
}
