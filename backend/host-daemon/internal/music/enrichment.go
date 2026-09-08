package music

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"sync"
	"time"
)

// EnrichedMetadata holds canonical track tags and high-res cover art.
type EnrichedMetadata struct {
	Title       string `json:"title"`
	Artist      string `json:"artist"`
	Album       string `json:"album"`
	AlbumArtist string `json:"album_artist"`
	TrackNumber int    `json:"track_number"`
	Year        int    `json:"year"`
	Genre       string `json:"genre"`
	ISRC        string `json:"isrc"`
	CoverArtURL string `json:"cover_art_url"`
}

var enrichmentHTTPClient = &http.Client{
	Timeout: 5 * time.Second,
}

// CleanTitle removes video artifacts like "(Official Video)", "[4K]", "ft. X", etc.
func CleanTitle(raw string) (cleaned string, extraArtist string) {
	s := raw
	// Common video tags to strip
	tags := []string{
		"(official video)", "[official video]", "(official audio)", "[official audio]",
		"(official music video)", "[official music video]", "(music video)", "[music video]",
		"(lyrics)", "[lyrics]", "(lyric video)", "[lyric video]", "(audio)", "[audio]",
		"(hd)", "[hd]", "(4k)", "[4k]", "(visualizer)", "[visualizer]", "(clip officiel)",
	}
	sLower := strings.ToLower(s)
	for _, tag := range tags {
		if idx := strings.Index(sLower, tag); idx >= 0 {
			s = s[:idx] + s[idx+len(tag):]
			sLower = strings.ToLower(s)
		}
	}

	// Extract features if present
	featMarkers := []string{" feat. ", " ft. ", " feat ", " ft "}
	for _, m := range featMarkers {
		if idx := strings.Index(strings.ToLower(s), m); idx >= 0 {
			extraArtist = strings.Trim(s[idx+len(m):], "()[] ")
			s = s[:idx]
			break
		}
	}

	return strings.TrimSpace(s), strings.TrimSpace(extraArtist)
}

// EnrichMetadata queries public Deezer and iTunes endpoints concurrently to acquire
// canonical metadata, official album title, genre, year, ISRC, and ultra-high-res album art (>= 1400x1400).
func EnrichMetadata(ctx context.Context, title, artist string) EnrichedMetadata {
	cleanTitle, extraArtist := CleanTitle(title)
	effectiveArtist := artist
	if effectiveArtist == "" && extraArtist != "" {
		effectiveArtist = extraArtist
	}

	// Default metadata from inputs
	meta := EnrichedMetadata{
		Title:       cleanTitle,
		Artist:      effectiveArtist,
		AlbumArtist: effectiveArtist,
		Year:        time.Now().Year(),
	}

	query := strings.TrimSpace(effectiveArtist + " " + cleanTitle)
	if query == "" {
		return meta
	}

	var wg sync.WaitGroup
	var mu sync.Mutex

	// 1. Query Deezer API (excellent for ISRC and album data)
	wg.Add(1)
	go func() {
		defer wg.Done()
		dMeta, err := queryDeezer(ctx, query)
		if err == nil {
			mu.Lock()
			if dMeta.Title != "" {
				meta.Title = dMeta.Title
			}
			if dMeta.Artist != "" {
				meta.Artist = dMeta.Artist
				meta.AlbumArtist = dMeta.Artist
			}
			if dMeta.Album != "" {
				meta.Album = dMeta.Album
			}
			if dMeta.ISRC != "" {
				meta.ISRC = dMeta.ISRC
			}
			if dMeta.CoverArtURL != "" && meta.CoverArtURL == "" {
				meta.CoverArtURL = dMeta.CoverArtURL
			}
			mu.Unlock()
		}
	}()

	// 2. Query iTunes API (excellent for Genre, Year, and 1400x1400 art)
	wg.Add(1)
	go func() {
		defer wg.Done()
		itMeta, err := queryiTunes(ctx, query)
		if err == nil {
			mu.Lock()
			if itMeta.Genre != "" {
				meta.Genre = itMeta.Genre
			}
			if itMeta.Year > 0 {
				meta.Year = itMeta.Year
			}
			if itMeta.TrackNumber > 0 {
				meta.TrackNumber = itMeta.TrackNumber
			}
			if itMeta.CoverArtURL != "" {
				// iTunes allows scaling up to 1400x1400
				meta.CoverArtURL = itMeta.CoverArtURL
			}
			if meta.Album == "" && itMeta.Album != "" {
				meta.Album = itMeta.Album
			}
			mu.Unlock()
		}
	}()

	wg.Wait()
	return meta
}

func queryDeezer(ctx context.Context, query string) (EnrichedMetadata, error) {
	reqURL := "https://api.deezer.com/search?q=" + url.QueryEscape(query)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, reqURL, nil)
	if err != nil {
		return EnrichedMetadata{}, err
	}

	resp, err := enrichmentHTTPClient.Do(req)
	if err != nil {
		return EnrichedMetadata{}, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return EnrichedMetadata{}, fmt.Errorf("deezer status %d", resp.StatusCode)
	}

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return EnrichedMetadata{}, err
	}

	var res struct {
		Data []struct {
			Title  string `json:"title"`
			ISRC   string `json:"isrc"`
			Artist struct {
				Name string `json:"name"`
			} `json:"artist"`
			Album struct {
				Title   string `json:"title"`
				CoverXL string `json:"cover_xl"`
			} `json:"album"`
		} `json:"data"`
	}

	if err := json.Unmarshal(data, &res); err != nil || len(res.Data) == 0 {
		return EnrichedMetadata{}, fmt.Errorf("no deezer results")
	}

	top := res.Data[0]
	return EnrichedMetadata{
		Title:       top.Title,
		Artist:      top.Artist.Name,
		Album:       top.Album.Title,
		ISRC:        top.ISRC,
		CoverArtURL: top.Album.CoverXL,
	}, nil
}

func queryiTunes(ctx context.Context, query string) (EnrichedMetadata, error) {
	reqURL := "https://itunes.apple.com/search?term=" + url.QueryEscape(query) + "&entity=song&limit=1"
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, reqURL, nil)
	if err != nil {
		return EnrichedMetadata{}, err
	}

	resp, err := enrichmentHTTPClient.Do(req)
	if err != nil {
		return EnrichedMetadata{}, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return EnrichedMetadata{}, fmt.Errorf("itunes status %d", resp.StatusCode)
	}

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return EnrichedMetadata{}, err
	}

	var res struct {
		Results []struct {
			TrackName      string `json:"trackName"`
			ArtistName     string `json:"artistName"`
			CollectionName string `json:"collectionName"`
			ArtworkUrl100  string `json:"artworkUrl100"`
			PrimaryGenre   string `json:"primaryGenreName"`
			ReleaseDate    string `json:"releaseDate"`
			TrackNumber    int    `json:"trackNumber"`
		} `json:"results"`
	}

	if err := json.Unmarshal(data, &res); err != nil || len(res.Results) == 0 {
		return EnrichedMetadata{}, fmt.Errorf("no itunes results")
	}

	top := res.Results[0]
	// Scale to ultra high-res 1400x1400
	hiResArt := strings.ReplaceAll(top.ArtworkUrl100, "100x100bb.jpg", "1400x1400bb.jpg")
	year := 0
	if len(top.ReleaseDate) >= 4 {
		year, _ = strconv.Atoi(top.ReleaseDate[:4])
	}

	return EnrichedMetadata{
		Title:       top.TrackName,
		Artist:      top.ArtistName,
		Album:       top.CollectionName,
		Genre:       top.PrimaryGenre,
		Year:        year,
		TrackNumber: top.TrackNumber,
		CoverArtURL: hiResArt,
	}, nil
}
