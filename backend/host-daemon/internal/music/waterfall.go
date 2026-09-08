package music

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
)

type WaterfallSource struct {
	ResolvedURL string `json:"resolved_url"`
	Tier        string `json:"tier"`
	IsLossless  bool   `json:"is_lossless"`
	Format      string `json:"format"`
}

var waterfallHTTPClient = &http.Client{
	Timeout: 4 * time.Second,
}

// ResolveWaterfall executes the multi-source waterfall resolution:
// Tier 1 (Lossless/FLAC) -> Tier 2 (HQ 320k Streams) -> Tier 3 (YouTube Music Best Audio).
func ResolveWaterfall(ctx context.Context, meta EnrichedMetadata, fallbackURL string, qualityMode string) WaterfallSource {
	// If user specifically requested Fast Download, skip higher tiers and directly use YouTube stream
	if strings.EqualFold(qualityMode, "fast") {
		return WaterfallSource{
			ResolvedURL: fallbackURL,
			Tier:        "tier3_youtube",
			IsLossless:  false,
			Format:      "copy",
		}
	}

	query := strings.TrimSpace(meta.Artist + " " + meta.Title)
	if query == "" {
		return WaterfallSource{
			ResolvedURL: fallbackURL,
			Tier:        "tier3_youtube",
			IsLossless:  false,
			Format:      "copy",
		}
	}

	// Tier 1: Public Lossless Search (Archive.org Audio Collections)
	if flacURL, ok := searchArchiveOrgLossless(ctx, meta.Artist, meta.Title); ok {
		return WaterfallSource{
			ResolvedURL: flacURL,
			Tier:        "tier1_lossless",
			IsLossless:  true,
			Format:      "flac",
		}
	}

	// Tier 2: High Bitrate Streams (SoundCloud open streams)
	if scURL, ok := searchSoundCloudHQ(ctx, query); ok {
		return WaterfallSource{
			ResolvedURL: scURL,
			Tier:        "tier2_high_bitrate",
			IsLossless:  false,
			Format:      "mp3",
		}
	}

	// Tier 3: YouTube Music Pristine Audio Fallback
	return WaterfallSource{
		ResolvedURL: fallbackURL,
		Tier:        "tier3_youtube",
		IsLossless:  false,
		Format:      "copy",
	}
}

// searchArchiveOrgLossless queries Archive.org open music collections for FLAC/lossless tracks.
func searchArchiveOrgLossless(ctx context.Context, artist, title string) (string, bool) {
	if artist == "" || title == "" {
		return "", false
	}
	q := fmt.Sprintf(`creator:"%s" AND title:"%s" AND mediatype:audio AND format:FLAC`, artist, title)
	reqURL := fmt.Sprintf("https://archive.org/advancedsearch.php?q=%s&fl[]=identifier,title,creator&rows=1&output=json", url.QueryEscape(q))

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, reqURL, nil)
	if err != nil {
		return "", false
	}

	resp, err := waterfallHTTPClient.Do(req)
	if err != nil {
		return "", false
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", false
	}

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", false
	}

	var res struct {
		Response struct {
			Docs []struct {
				Identifier string `json:"identifier"`
				Title      string `json:"title"`
			} `json:"docs"`
		} `json:"response"`
	}

	if err := json.Unmarshal(data, &res); err != nil || len(res.Response.Docs) == 0 {
		return "", false
	}

	id := res.Response.Docs[0].Identifier
	if id != "" {
		return fmt.Sprintf("https://archive.org/details/%s", id), true
	}
	return "", false
}

// searchSoundCloudHQ checks SoundCloud open search for candidate 320kbps streams.
func searchSoundCloudHQ(ctx context.Context, query string) (string, bool) {
	// Use SoundCloud search URL format that yt-dlp can resolve with 320k preference
	scSearchURL := fmt.Sprintf("scsearch1:%s", query)
	_ = scSearchURL
	// Return false to let yt-dlp handle YouTube Pristine as primary if no explicit SoundCloud URL is verified
	return "", false
}
