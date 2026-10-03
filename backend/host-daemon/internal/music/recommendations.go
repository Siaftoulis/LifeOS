package music

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"
)

type RecommendedTrack struct {
	ID               string  `json:"id"`
	Title            string  `json:"title"`
	Artist           string  `json:"artist"`
	Album            string  `json:"album,omitempty"`
	Genre            string  `json:"genre,omitempty"`
	Year             int     `json:"year,omitempty"`
	Duration         float64 `json:"duration"`
	Thumbnail        string  `json:"thumbnail"`
	IsLocal          bool    `json:"is_local"`
	FilePath         string  `json:"file_path,omitempty"`
	StreamURL        string  `json:"stream_url"`
	IsRadioDiscovery bool    `json:"is_radio_discovery,omitempty"`
}

type recCacheEntry struct {
	tracks    []RecommendedTrack
	expiresAt time.Time
}

var (
	recMu    sync.RWMutex
	recCache = make(map[string]recCacheEntry)
)

const recCacheTTL = 30 * time.Minute

// FetchYouTubeMusicRadio queries YouTube Music's algorithmic radio list (RDAMVM<seedID>)
// with fallback to standard YouTube radio (RD<seedID>), returning enriched tracks.
func FetchYouTubeMusicRadio(ctx context.Context, seedID string, limit int) ([]RecommendedTrack, error) {
	return FetchYouTubeMusicRadioVibe(ctx, seedID, "", "", "", limit)
}

// FetchYouTubeMusicRadioVibe executes smart vibe-based radio recommendation
// incorporating candidate ranking, user SQLite affinities, artist diversity, and serendipity.
func FetchYouTubeMusicRadioVibe(ctx context.Context, seedID, seedArtist, seedGenre, seedTitle string, limit int) ([]RecommendedTrack, error) {
	if limit <= 0 {
		limit = 15
	}
	if limit > 30 {
		limit = 30
	}

	seedID = strings.TrimSpace(seedID)
	if seedID == "" {
		return nil, fmt.Errorf("empty seed ID")
	}

	cacheKey := seedID
	if seedArtist != "" || seedGenre != "" || seedTitle != "" {
		cacheKey = fmt.Sprintf("%s:%s:%s:%s", seedID, seedArtist, seedGenre, seedTitle)
	}

	// 1. Check in-memory cache
	recMu.RLock()
	entry, ok := recCache[cacheKey]
	if !ok && cacheKey != seedID {
		entry, ok = recCache[seedID]
	}
	if ok && time.Now().Before(entry.expiresAt) {
		recMu.RUnlock()
		if len(entry.tracks) > limit {
			return entry.tracks[:limit], nil
		}
		return entry.tracks, nil
	}
	recMu.RUnlock()

	// 2. Query YouTube Music Algorithmic Radio via yt-dlp (pull 30 candidate tracks)
	var targetURL string
	if len(seedID) == 11 {
		targetURL = fmt.Sprintf("https://music.youtube.com/watch?v=%s&list=RDAMVM%s", seedID, seedID)
	} else if seedArtist != "" {
		targetURL = fmt.Sprintf("ytsearch%d:%s songs audio", limit+15, seedArtist)
	} else {
		targetURL = fmt.Sprintf("ytsearch%d:%s songs audio", limit+15, seedID)
	}

	args := []string{
		"--js-runtimes", jsRuntimesArg(),
		"--extractor-args", "youtube:player_client=android,web",
		"--flat-playlist",
		"--dump-single-json",
		"--no-warnings",
		"--no-check-certificates",
		"--playlist-items", fmt.Sprintf("1:%d", limit+15),
		targetURL,
	}

	out, err := ExecYtDlp(ctx, "recommendations-radio", seedID, args)
	if err != nil || len(out) == 0 {
		if len(seedID) == 11 {
			// Fallback to standard YouTube radio (RD<seedID>)
			fallbackURL := fmt.Sprintf("https://www.youtube.com/watch?v=%s&list=RD%s", seedID, seedID)
			args[len(args)-1] = fallbackURL
			out, err = ExecYtDlp(ctx, "recommendations-fallback", seedID, args)
		}
		if err != nil || len(out) == 0 {
			return nil, fmt.Errorf("radio extraction failed: %w", err)
		}
	}

	var seedTitleFromDB string
	if DB != nil {
		_ = DB.QueryRowContext(ctx, "SELECT title FROM music_tracks WHERE id = ? OR yt_dlp_id = ? LIMIT 1", seedID, seedID).Scan(&seedTitleFromDB)
	}
	effectiveSeedTitle := strings.TrimSpace(seedTitleFromDB)
	if effectiveSeedTitle == "" {
		effectiveSeedTitle = strings.TrimSpace(seedTitle)
	}

	var dump flatDump
	if err := json.Unmarshal(out, &dump); err != nil || len(dump.Entries) == 0 {
		return nil, fmt.Errorf("failed to parse radio dump: %v", err)
	}

	candidates := make([]RecommendedTrack, 0, len(dump.Entries))
	seen := make(map[string]bool)

	for _, e := range dump.Entries {
		if e.ID == "" || e.Title == "" || seen[e.ID] || e.ID == seedID {
			continue
		}
		// Strict music track duration: standard songs are between 50s and 8 minutes (480s)
		if e.Duration > 480 || (e.Duration > 0 && e.Duration < 50) {
			continue
		}

		lowerRaw := strings.ToLower(e.Title)
		// Strictly filter out podcasts, full albums, multi-track mixes, reviews, reactions
		if strings.Contains(lowerRaw, "podcast") ||
			strings.Contains(lowerRaw, "full album") ||
			strings.Contains(lowerRaw, "hour mix") ||
			strings.Contains(lowerRaw, "10 hours") ||
			strings.Contains(lowerRaw, "1 hour") ||
			strings.Contains(lowerRaw, "compilation") ||
			strings.Contains(lowerRaw, "reaction") ||
			strings.Contains(lowerRaw, "review") ||
			strings.Contains(lowerRaw, "interview") ||
			strings.Contains(lowerRaw, "episode") ||
			strings.Contains(lowerRaw, "season") ||
			strings.Contains(lowerRaw, "dj mix") ||
			strings.Contains(lowerRaw, "megamix") {
			continue
		}

		cleanTitle, extraArtist := CleanTitle(e.Title)
		if cleanTitle == "" {
			cleanTitle = e.Title
		}

		lowerClean := strings.ToLower(cleanTitle)
		lowerSeed := strings.ToLower(effectiveSeedTitle)

		// Avoid replaying songs with identical title or substring match with seed track
		if lowerSeed != "" {
			if strings.EqualFold(cleanTitle, effectiveSeedTitle) ||
				strings.Contains(lowerClean, lowerSeed) ||
				strings.Contains(lowerSeed, lowerClean) {
				continue
			}
		}

		// Filter out remixes, club edits, covers, VIPs unless original was explicitly a remix
		if (strings.Contains(lowerClean, "remix") ||
			strings.Contains(lowerClean, "club mix") ||
			strings.Contains(lowerClean, "vip edit") ||
			strings.Contains(lowerClean, "cover") ||
			strings.Contains(lowerClean, "karaoke") ||
			strings.Contains(lowerClean, "tribute") ||
			strings.Contains(lowerClean, "slowed") ||
			strings.Contains(lowerClean, "reverb")) &&
			!strings.Contains(lowerSeed, "remix") {
			continue
		}

		seen[e.ID] = true

		artist := strings.TrimSpace(e.Uploader)
		if (artist == "" || strings.EqualFold(artist, "YouTube Music")) && extraArtist != "" {
			artist = extraArtist
		}
		if isViewOrCountToken(artist) || strings.Contains(artist, "•") {
			artist = strings.TrimSpace(strings.ReplaceAll(artist, "•", ""))
		}
		if artist == "" {
			artist = "YouTube Music"
		}

		thumb := upgradeThumbnailQuality(extractThumbnail(e.Thumbnails, e.ID))
		track := RecommendedTrack{
			ID:        e.ID,
			Title:     cleanTitle,
			Artist:    artist,
			Duration:  e.Duration,
			Thumbnail: thumb,
			StreamURL: fmt.Sprintf("/api/v1/music/ytstream/stream.m4a?id=%s&proxy=true", e.ID),
			IsLocal:   false,
		}

		// Enrich with local SQLite vault metadata if already downloaded
		if DB != nil {
			var localID, filePath, album, genre string
			var year int
			err := DB.QueryRowContext(ctx,
				"SELECT id, file_path, album, genre, year FROM music_tracks WHERE id = ? OR yt_dlp_id = ? LIMIT 1",
				e.ID, e.ID,
			).Scan(&localID, &filePath, &album, &genre, &year)
			if err == nil && filePath != "" {
				track.IsLocal = true
				track.FilePath = filePath
				track.StreamURL = fmt.Sprintf("/api/v1/music/stream/?id=%s&proxy=true", localID)
				track.Album = album
				track.Genre = genre
				track.Year = year
			}
		}

		candidates = append(candidates, track)
	}

	// 5. Multi-factor Scoring & Curated Assembly with Artist Diversity & Serendipity
	profile := GetUserAffinityProfile(ctx)

	type scoredCand struct {
		track RecommendedTrack
		score float64
	}
	scored := make([]scoredCand, 0, len(candidates))
	for i, c := range candidates {
		isSerendipity := (i%3 == 2)
		s := ScoreRecommendation(c, seedArtist, seedGenre, profile, isSerendipity)
		if c.IsLocal {
			s += 0.25 // Boost locally cached/downloaded tracks
		}
		c.IsRadioDiscovery = isSerendipity
		scored = append(scored, scoredCand{track: c, score: s})
	}

	// Sort candidates by score descending
	sort.SliceStable(scored, func(i, j int) bool {
		return scored[i].score > scored[j].score
	})

	results := make([]RecommendedTrack, 0, limit)
	selectedIDs := make(map[string]bool)
	artistCounts := make(map[string]int)

	for _, sc := range scored {
		if len(results) >= limit {
			break
		}
		if selectedIDs[sc.track.ID] {
			continue
		}
		artKey := strings.ToLower(strings.TrimSpace(sc.track.Artist))
		if artKey != "" && artistCounts[artKey] >= 2 {
			continue // Max 2 tracks per artist in the radio queue
		}
		selectedIDs[sc.track.ID] = true
		if artKey != "" {
			artistCounts[artKey]++
		}
		results = append(results, sc.track)
	}

	// 6. Save into cache
	recMu.Lock()
	recCache[cacheKey] = recCacheEntry{
		tracks:    results,
		expiresAt: time.Now().Add(recCacheTTL),
	}
	recMu.Unlock()

	return results, nil
}

// GetPersonalizedSeed searches the user's history and liked tracks for the best YouTube seed.
func GetPersonalizedSeed(ctx context.Context) string {
	if DB == nil {
		return ""
	}

	// 1. Most recently played track
	var seedID, title, artist string
	err := DB.QueryRowContext(ctx, `
		SELECT COALESCE(NULLIF(mt.yt_dlp_id, ''), mt.id), mt.title, mt.artist
		FROM listening_history lh
		JOIN music_tracks mt ON lh.track_id = mt.id
		ORDER BY lh.played_at DESC
		LIMIT 1
	`).Scan(&seedID, &title, &artist)

	if err == nil && len(seedID) == 11 {
		return seedID
	}

	// 2. Most played or liked track
	err = DB.QueryRowContext(ctx, `
		SELECT COALESCE(NULLIF(yt_dlp_id, ''), id), title, artist
		FROM music_tracks
		ORDER BY play_count DESC, added_at DESC
		LIMIT 1
	`).Scan(&seedID, &title, &artist)

	if err == nil && len(seedID) == 11 {
		return seedID
	}

	// If we found a title/artist but no 11-char YouTube ID, search for it
	if title != "" {
		q := title
		if artist != "" {
			q += " " + artist
		}
		args := []string{
			"--js-runtimes", jsRuntimesArg(),
			"--flat-playlist",
			"--dump-single-json",
			"--no-warnings",
			"--no-check-certificates",
			"--playlist-items", "1:1",
			"ytsearch1:" + q,
		}
		out, err := ExecYtDlp(ctx, "resolve-seed", q, args)
		if err == nil {
			var dump flatDump
			if err := json.Unmarshal(out, &dump); err == nil && len(dump.Entries) > 0 {
				return dump.Entries[0].ID
			}
		}
	}

	return ""
}

// HandleRecommendations handles GET /api/v1/music/recommendations and GET /api/v1/music/smart/recommendations
func HandleRecommendations(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	// Mode parameter: if local requested, delegate to smart SQLite playlist
	if r.URL.Query().Get("mode") == "local" {
		HandleLocalRecommendations(w, r)
		return
	}

	limit := 15
	if l := r.URL.Query().Get("limit"); l != "" {
		if v, err := strconv.Atoi(l); err == nil && v > 0 {
			limit = v
		}
	}

	seed := strings.TrimSpace(r.URL.Query().Get("id"))
	if seed == "" {
		seed = strings.TrimSpace(r.URL.Query().Get("seed"))
	}
	if seed == "" {
		seed = strings.TrimSpace(r.URL.Query().Get("track_id"))
	}

	ctx, cancel := context.WithTimeout(r.Context(), defaultSearchTimeout)
	defer cancel()

	// If seed is not provided, resolve personal seed from history
	if seed == "" {
		seed = GetPersonalizedSeed(ctx)
	}

	seedArtist := strings.TrimSpace(r.URL.Query().Get("artist"))
	seedGenre := strings.TrimSpace(r.URL.Query().Get("genre"))
	var trackTitle string
	if t := strings.TrimSpace(r.URL.Query().Get("title")); t != "" {
		trackTitle = t
	}
	// If seed is a local track ID or custom ID, resolve metadata from SQLite
	if seed != "" && len(seed) != 11 {
		var localYtID, localTitle, localArt, localGen sql.NullString
		if DB != nil {
			_ = DB.QueryRowContext(ctx,
				"SELECT yt_dlp_id, title, artist, genre FROM music_tracks WHERE id = ? LIMIT 1", seed,
			).Scan(&localYtID, &localTitle, &localArt, &localGen)
		}
		if len(localYtID.String) == 11 {
			seed = localYtID.String
		}
		if trackTitle == "" && localTitle.Valid {
			trackTitle = localTitle.String
		}
		if seedArtist == "" && localArt.Valid {
			seedArtist = localArt.String
		}
		if seedGenre == "" && localGen.Valid {
			seedGenre = localGen.String
		}
	}

	if seed != "" && (seedArtist == "" || seedGenre == "") {
		dbArt, dbGen := FindTrackArtistAndGenre(ctx, seed)
		if seedArtist == "" {
			seedArtist = dbArt
		}
		if seedGenre == "" {
			seedGenre = dbGen
		}
	}

	var tracks []RecommendedTrack
	var err error

	if seed != "" {
		tracks, err = FetchYouTubeMusicRadioVibe(ctx, seed, seedArtist, seedGenre, trackTitle, limit)
	}

	// If radio extraction failed or no seed found, fall back to artist/genre music radio search
	if err != nil || len(tracks) == 0 {
		log.Printf("recommendations: radio fallback for seed %q (err: %v)", seed, err)
		fallbackQuery := "ytsearch25:trending music songs audio"
		if seedArtist != "" {
			fallbackQuery = fmt.Sprintf("ytsearch25:%s songs audio", seedArtist)
		} else if seedGenre != "" {
			fallbackQuery = fmt.Sprintf("ytsearch25:%s top hits songs audio", seedGenre)
		} else if seed != "" && len(seed) == 11 {
			fallbackQuery = fmt.Sprintf("ytsearch25:%s song audio", seed)
		}
		args := []string{
			"--js-runtimes", jsRuntimesArg(),
			"--flat-playlist",
			"--dump-single-json",
			"--no-warnings",
			"--no-check-certificates",
			fallbackQuery,
		}
		out, fErr := ExecYtDlp(ctx, "recommendations-trending", fallbackQuery, args)
		if fErr == nil {
			var dump flatDump
			if err := json.Unmarshal(out, &dump); err == nil && len(dump.Entries) > 0 {
				tracks = make([]RecommendedTrack, 0, len(dump.Entries))
				fallbackArtistCounts := make(map[string]int)
				for _, e := range dump.Entries {
					if e.ID == "" || e.Title == "" || e.IsLive || e.LiveStatus == "is_live" || e.Duration <= 0 || e.Duration > maxSongSeconds || (seed != "" && e.ID == seed) {
						continue
					}
					cleanTitle, extraArtist := CleanTitle(e.Title)
					if cleanTitle == "" {
						cleanTitle = e.Title
					}
					lowerClean := strings.ToLower(cleanTitle)
					lowerSeed := strings.ToLower(strings.TrimSpace(trackTitle))
					if lowerSeed != "" {
						if strings.EqualFold(cleanTitle, trackTitle) ||
							strings.Contains(lowerClean, lowerSeed) ||
							strings.Contains(lowerSeed, lowerClean) {
							continue
						}
					}
					if (strings.Contains(lowerClean, "remix") ||
						strings.Contains(lowerClean, "club mix") ||
						strings.Contains(lowerClean, "vip edit") ||
						strings.Contains(lowerClean, "cover") ||
						strings.Contains(lowerClean, "karaoke") ||
						strings.Contains(lowerClean, "tribute") ||
						strings.Contains(lowerClean, "slowed") ||
						strings.Contains(lowerClean, "reverb")) &&
						!strings.Contains(lowerSeed, "remix") {
						continue
					}
					art := strings.TrimSpace(e.Uploader)
					if (art == "" || strings.EqualFold(art, "YouTube Music")) && extraArtist != "" {
						art = extraArtist
					}
					artKey := strings.ToLower(art)
					if artKey != "" && fallbackArtistCounts[artKey] >= 2 {
						continue
					}
					if artKey != "" {
						fallbackArtistCounts[artKey]++
					}
					tracks = append(tracks, RecommendedTrack{
						ID:        e.ID,
						Title:     cleanTitle,
						Artist:    art,
						Duration:  e.Duration,
						Thumbnail: upgradeThumbnailQuality(extractThumbnail(e.Thumbnails, e.ID)),
						StreamURL: fmt.Sprintf("/api/v1/music/ytstream/stream.m4a?id=%s&proxy=true", e.ID),
						IsLocal:   false,
					})
					if len(tracks) >= limit {
						break
					}
				}
			}
		}
	}

	// If still empty (e.g. completely offline), fall back to local smart playlist recommendations
	if len(tracks) == 0 {
		q := r.URL.Query()
		if seedArtist != "" && q.Get("artist") == "" {
			q.Set("artist", seedArtist)
		}
		if seedGenre != "" && q.Get("genre") == "" {
			q.Set("genre", seedGenre)
		}
		r.URL.RawQuery = q.Encode()
		HandleLocalRecommendations(w, r)
		return
	}

	json.NewEncoder(w).Encode(tracks)
}
