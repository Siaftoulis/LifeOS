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
		SELECT mt.id, mt.title, mt.artist, mt.album, mt.album_artist, mt.track_number, mt.disc_number, mt.year, mt.genre,
		       mt.file_path, mt.lyrics_path, COALESCE(NULLIF(mt.thumbnail, ''), mt.thumbnail_url, ''), mt.yt_dlp_id, mt.duration, mt.bitrate, mt.codec,
		       mt.replay_gain_track, mt.replay_gain_album, mt.play_count, mt.last_played_at, mt.added_at
		FROM music_tracks mt
		JOIN liked_songs ls ON ls.id = mt.id
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
		TrackID string `json:"track_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.TrackID == "" {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	var exists int
	err := DB.QueryRow("SELECT 1 FROM liked_songs WHERE id = ?", req.TrackID).Scan(&exists)
	if err == sql.ErrNoRows {
		_, err = DB.Exec("INSERT INTO liked_songs (id, liked_at) VALUES (?, ?)", req.TrackID, time.Now().UnixMilli())
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
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
