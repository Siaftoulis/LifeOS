package music

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"strconv"
	"time"
)

func HandleDiscoveryWeekly(w http.ResponseWriter, r *http.Request) {
	handleSmartPlaylist(w, r, "discovery_weekly")
}

func HandleDailyMix(w http.ResponseWriter, r *http.Request) {
	handleSmartPlaylist(w, r, "daily_mix")
}

func HandleReleaseRadar(w http.ResponseWriter, r *http.Request) {
	handleSmartPlaylist(w, r, "release_radar")
}

func HandleRecommendations(w http.ResponseWriter, r *http.Request) {
	handleSmartPlaylist(w, r, "recommendations")
}

func handleSmartPlaylist(w http.ResponseWriter, r *http.Request, ptype string) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	limit := 50
	if l := r.URL.Query().Get("limit"); l != "" {
		if v, err := strconv.Atoi(l); err == nil {
			limit = v
		}
	}

	var query string
	seed := r.URL.Query().Get("seed")
	now := time.Now()
	since := now.AddDate(0, -3, 0).UnixMilli() // 90 days

	switch ptype {
	case "discovery_weekly":
		query = `
			SELECT DISTINCT mt.id, mt.title, mt.artist, mt.album, mt.album_artist, mt.track_number, mt.disc_number, mt.year, mt.genre,
			       mt.file_path, mt.lyrics_path, mt.thumbnail_url, mt.yt_dlp_id, mt.duration, mt.bitrate, mt.codec,
			       mt.replay_gain_track, mt.replay_gain_album, mt.play_count, mt.last_played_at, mt.added_at
			FROM music_tracks mt
			WHERE mt.id NOT IN (
				SELECT track_id FROM listening_history WHERE played_at > ?
			)
			AND mt.artist IN (
				SELECT artist FROM music_tracks
				WHERE id IN (SELECT track_id FROM listening_history WHERE played_at > ?)
				GROUP BY artist ORDER BY COUNT(*) DESC LIMIT 15
			)
			ORDER BY RANDOM()
			LIMIT ?
		`
	case "daily_mix":
		if seed == "" {
			http.Error(w, "Missing seed parameter for daily_mix", http.StatusBadRequest)
			return
		}
		query = `
			SELECT * FROM music_tracks
			WHERE (artist = ? OR genre = ?)
			ORDER BY play_count DESC, added_at DESC
			LIMIT ?
		`
	case "release_radar":
		recentDays := 14
		if d := r.URL.Query().Get("days"); d != "" {
			if v, err := strconv.Atoi(d); err == nil {
				recentDays = v
			}
		}
		since = now.AddDate(0, 0, -recentDays).UnixMilli()
		query = `
			SELECT mt.* FROM music_tracks mt
			WHERE mt.added_at > ?
			AND mt.artist IN (
				SELECT DISTINCT artist FROM music_tracks
				WHERE id IN (SELECT track_id FROM listening_history WHERE played_at > ?)
			)
			ORDER BY mt.added_at DESC
			LIMIT ?
		`
	case "recommendations":
		query = `
			SELECT DISTINCT mt.* FROM music_tracks mt
			WHERE mt.id NOT IN (
				SELECT track_id FROM listening_history WHERE played_at > ?
			)
			AND (mt.artist IN (
				SELECT artist FROM music_tracks
				WHERE id IN (SELECT track_id FROM listening_history WHERE played_at > ?)
				GROUP BY artist ORDER BY COUNT(*) DESC LIMIT 10
			) OR mt.genre IN (
				SELECT genre FROM music_tracks
				WHERE id IN (SELECT track_id FROM listening_history WHERE played_at > ?)
				GROUP BY genre ORDER BY COUNT(*) DESC LIMIT 5
			))
			ORDER BY mt.play_count DESC, mt.added_at DESC
			LIMIT ?
		`
	}

	var rows *sql.Rows
	var err error
	if ptype == "daily_mix" {
		rows, err = DB.Query(query, seed, seed, limit)
	} else if ptype == "release_radar" {
		rows, err = DB.Query(query, since, since, limit)
	} else {
		rows, err = DB.Query(query, since, since, since, limit)
	}
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var tracks []Track
	for rows.Next() {
		var t Track
		var albumArtist, genre, filePath, lyricsPath, thumbUrl, ytDlpId, codec sql.NullString
		var trackNum, discNum, year, bitrate sql.NullInt64
		var replayTrack, replayAlbum sql.NullFloat64
		var playCount sql.NullInt64
		var lastPlayed, addedAt sql.NullInt64
		if err := rows.Scan(&t.ID, &t.Title, &t.Artist, &t.Album, &albumArtist, &trackNum, &discNum, &year, &genre,
			&filePath, &lyricsPath, &thumbUrl, &ytDlpId, &t.Duration, &bitrate, &codec,
			&replayTrack, &replayAlbum, &playCount, &lastPlayed, &addedAt); err == nil {
			tracks = append(tracks, t)
		}
	}
	if tracks == nil {
		tracks = []Track{}
	}
	json.NewEncoder(w).Encode(tracks)
}
