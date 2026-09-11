package music

import (
	"context"
	"math"
	"strings"
	"time"
)

// UserAffinityProfile stores computed user taste affinities.
type UserAffinityProfile struct {
	ArtistScores map[string]float64
	GenreScores  map[string]float64
}

// UpdateUserAffinity updates the user's genre and artist affinity tables in SQLite
// based on playback completion, skips, or likes.
func UpdateUserAffinity(ctx context.Context, artist, genre string, completionRate float64, skipped bool, isLike bool) {
	if DB == nil {
		return
	}

	artist = strings.TrimSpace(artist)
	genre = strings.TrimSpace(genre)
	if artist == "" && genre == "" {
		return
	}

	now := time.Now().UnixMilli()

	var playDelta, likeDelta, skipDelta int
	var scoreDelta float64

	if isLike {
		likeDelta = 1
		scoreDelta = 0.50
	} else if skipped && completionRate < 0.25 {
		skipDelta = 1
		scoreDelta = -0.25 // Penalty for early skips
	} else if completionRate >= 0.70 {
		playDelta = 1
		scoreDelta = 0.15 // Reward for high completion
	} else {
		playDelta = 1
		scoreDelta = 0.03 // Mild reward for partial listen
	}

	// Update artist affinity if artist is valid and not generic
	if artist != "" && !strings.EqualFold(artist, "YouTube Music") && !strings.EqualFold(artist, "Unknown") {
		rawArtists := strings.FieldsFunc(artist, func(r rune) bool {
			return r == ',' || r == '&'
		})
		for _, a := range rawArtists {
			aClean := strings.TrimSpace(a)
			if aClean == "" || len(aClean) < 2 {
				continue
			}
			query := `
			INSERT INTO user_artist_affinity (artist, play_count, like_count, skip_count, affinity_score, updated_at)
			VALUES (?, ?, ?, ?, ?, ?)
			ON CONFLICT(artist) DO UPDATE SET
				play_count = MAX(0, user_artist_affinity.play_count + excluded.play_count),
				like_count = MAX(0, user_artist_affinity.like_count + excluded.like_count),
				skip_count = MAX(0, user_artist_affinity.skip_count + excluded.skip_count),
				affinity_score = MAX(-2.0, MIN(10.0, user_artist_affinity.affinity_score + excluded.affinity_score)),
				updated_at = excluded.updated_at
			`
			_, _ = DB.ExecContext(ctx, query, aClean, playDelta, likeDelta, skipDelta, scoreDelta, now)
		}
	}

	// Update genre affinity if genre is valid
	if genre != "" && !strings.EqualFold(genre, "Unknown") && !strings.EqualFold(genre, "Music") {
		query := `
		INSERT INTO user_genre_affinity (genre, play_count, like_count, skip_count, affinity_score, updated_at)
		VALUES (?, ?, ?, ?, ?, ?)
		ON CONFLICT(genre) DO UPDATE SET
			play_count = MAX(0, user_genre_affinity.play_count + excluded.play_count),
			like_count = MAX(0, user_genre_affinity.like_count + excluded.like_count),
			skip_count = MAX(0, user_genre_affinity.skip_count + excluded.skip_count),
			affinity_score = MAX(-2.0, MIN(10.0, user_genre_affinity.affinity_score + excluded.affinity_score)),
			updated_at = excluded.updated_at
		`
		_, _ = DB.ExecContext(ctx, query, genre, playDelta, likeDelta, skipDelta, scoreDelta, now)
	}
}

// GetUserAffinityProfile loads all known artist and genre affinity scores from SQLite.
func GetUserAffinityProfile(ctx context.Context) UserAffinityProfile {
	profile := UserAffinityProfile{
		ArtistScores: make(map[string]float64),
		GenreScores:  make(map[string]float64),
	}
	if DB == nil {
		return profile
	}

	// Load artist affinities
	rows, err := DB.QueryContext(ctx, "SELECT artist, affinity_score FROM user_artist_affinity")
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var art string
			var score float64
			if err := rows.Scan(&art, &score); err == nil {
				profile.ArtistScores[strings.ToLower(strings.TrimSpace(art))] = score
			}
		}
	}

	// Load genre affinities
	gRows, err := DB.QueryContext(ctx, "SELECT genre, affinity_score FROM user_genre_affinity")
	if err == nil {
		defer gRows.Close()
		for gRows.Next() {
			var gen string
			var score float64
			if err := gRows.Scan(&gen, &score); err == nil {
				profile.GenreScores[strings.ToLower(strings.TrimSpace(gen))] = score
			}
		}
	}

	return profile
}

// ScoreRecommendation computes a multi-factor ranking score for a candidate track.
// Formula:
// Score = 0.35 * VibeMatch + 0.25 * GenreAffinity + 0.20 * ArtistAffinity + 0.20 * Serendipity - Penalty
func ScoreRecommendation(
	track RecommendedTrack,
	seedArtist, seedGenre string,
	profile UserAffinityProfile,
	isSerendipitySlot bool,
) float64 {
	var score float64

	artLower := strings.ToLower(strings.TrimSpace(track.Artist))
	seedArtLower := strings.ToLower(strings.TrimSpace(seedArtist))
	seedGenLower := strings.ToLower(strings.TrimSpace(seedGenre))

	// 1. Vibe & Similarity Match (0.0 to 1.0)
	vibeMatch := 0.50
	if seedArtLower != "" && strings.Contains(artLower, seedArtLower) {
		// Same artist or featured
		vibeMatch = 0.85
	} else if seedGenLower != "" {
		// If album / genre hints match
		titleLower := strings.ToLower(track.Title)
		if strings.Contains(titleLower, seedGenLower) {
			vibeMatch += 0.20
		}
	}
	score += 0.35 * vibeMatch

	// 2. Genre Affinity (normalized from SQLite profile)
	var genreAffinity float64
	if seedGenLower != "" {
		if val, ok := profile.GenreScores[seedGenLower]; ok {
			genreAffinity = math.Tanh(val / 2.0) // Maps (-inf, +inf) cleanly to (-1, 1)
		}
	}
	score += 0.25 * genreAffinity

	// 3. Artist Affinity
	var artistAffinity float64
	if val, ok := profile.ArtistScores[artLower]; ok {
		artistAffinity = math.Tanh(val / 2.0)
	}
	score += 0.20 * artistAffinity

	// 4. Serendipity / Radio Discovery ("Σαν ραδιόφωνο")
	if isSerendipitySlot {
		// In a serendipity slot, reward tracks by different artists that fit the broad vibe
		if seedArtLower != "" && !strings.Contains(artLower, seedArtLower) {
			score += 0.35 // Exploratory hidden gem boost
		}
	}

	// 5. Clean Title Quality Bonus:
	// Penalize ugly live bootlegs, 1-hour loops, or low-effort fan uploads
	titleLower := strings.ToLower(track.Title)
	if strings.Contains(titleLower, "1 hour") || strings.Contains(titleLower, "10 hours") ||
		strings.Contains(titleLower, "reaction") || strings.Contains(titleLower, "karaoke") {
		score -= 1.0
	}

	return score
}

// FindTrackArtistAndGenre queries local DB or cache for a track's artist & genre.
func FindTrackArtistAndGenre(ctx context.Context, trackID string) (artist string, genre string) {
	if DB == nil || trackID == "" {
		return "", ""
	}
	_ = DB.QueryRowContext(ctx, `
		SELECT artist, genre FROM music_tracks
		WHERE id = ? OR yt_dlp_id = ?
		LIMIT 1
	`, trackID, trackID).Scan(&artist, &genre)

	if genre == "" {
		_ = DB.QueryRowContext(ctx, `
			SELECT genre FROM track_vibe_features
			WHERE track_id = ?
			LIMIT 1
		`, trackID).Scan(&genre)
	}
	return artist, genre
}
