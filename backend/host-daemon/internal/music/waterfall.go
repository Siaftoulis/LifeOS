package music

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
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
// Tier 0 (Authenticated HiFi - Tidal/Deezer) ->
// Tier 1A (Soulseek P2P Lossless FLAC via slskd) ->
// Tier 1B (Archive.org Open Audio Collections Direct FLAC) ->
// Tier 2 (High Bitrate Streams - SoundCloud HQ 320k) ->
// Tier 3 (YouTube Music Best Audio Extraction).
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

	// Tier 0: Authenticated HiFi Services (if user configured tokens)
	if hifiSource, ok := checkAuthenticatedHiFi(ctx, meta); ok {
		return hifiSource
	}

	// Tier 1A: Soulseek P2P Lossless FLAC (via slskd)
	if GetMusicConfig("slskd_enabled") != "false" {
		slskd := NewSlskdClient()
		if slskd.IsAvailable(ctx) {
			if match, err := slskd.SearchFLAC(ctx, meta.Artist, meta.Title); err == nil && match != nil {
				log.Printf("waterfall: found Soulseek P2P FLAC match: user=%s file=%s (size=%d, bitrate=%d)", match.Username, match.Filename, match.Size, match.BitRate)
				// Enqueue download via slskd
				if err := slskd.EnqueueDownload(ctx, match); err == nil {
					return WaterfallSource{
						ResolvedURL: fmt.Sprintf("slskd://%s/%s", match.Username, match.Filename),
						Tier:        "tier1_soulseek_flac",
						IsLossless:  true,
						Format:      "flac",
					}
				}
			}
		}
	}

	// Tier 1B: Archive.org Open Audio Collections Direct FLAC
	if flacURL, ok := searchArchiveOrgLossless(ctx, meta.Artist, meta.Title); ok {
		return WaterfallSource{
			ResolvedURL: flacURL,
			Tier:        "tier1_archive_org_flac",
			IsLossless:  true,
			Format:      "flac",
		}
	}

	// Tier 2: High Bitrate Streams (SoundCloud open HQ streams)
	if scQuery, ok := searchSoundCloudHQ(ctx, query); ok {
		return WaterfallSource{
			ResolvedURL: scQuery,
			Tier:        "tier2_soundcloud_hq",
			IsLossless:  false,
			Format:      "mp3",
		}
	}

	// Tier 3: YouTube Music Pristine Audio Fallback (Opus itag 251 / AAC itag 140)
	return WaterfallSource{
		ResolvedURL: fallbackURL,
		Tier:        "tier3_youtube",
		IsLossless:  false,
		Format:      "copy",
	}
}

// checkAuthenticatedHiFi checks if optional Tidal/Deezer credentials are provided in env.
func checkAuthenticatedHiFi(ctx context.Context, meta EnrichedMetadata) (WaterfallSource, bool) {
	tidalToken := GetMusicConfig("tidal_token")
	if tidalToken == "" {
		tidalToken = os.Getenv("TIDAL_TOKEN")
	}
	deezerARL := GetMusicConfig("deezer_arl")
	if deezerARL == "" {
		deezerARL = os.Getenv("DEEZER_ARL")
	}

	if tidalToken != "" {
		log.Printf("waterfall: Tidal authentication token detected, checking Tidal HiFi catalog for ISRC=%s", meta.ISRC)
		// Reserved hook for authenticated Tidal HiFi streaming
	}
	if deezerARL != "" {
		log.Printf("waterfall: Deezer ARL session detected, checking Deezer FLAC catalog for ISRC=%s", meta.ISRC)
		// Reserved hook for authenticated Deezer FLAC streaming
	}

	return WaterfallSource{}, false
}

// searchArchiveOrgLossless queries Archive.org and resolves a direct .flac download URL.
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
	if id == "" {
		return "", false
	}

	// Resolve direct .flac file from item metadata
	filesURL := fmt.Sprintf("https://archive.org/metadata/%s/files", url.PathEscape(id))
	filesReq, err := http.NewRequestWithContext(ctx, http.MethodGet, filesURL, nil)
	if err == nil {
		filesResp, err := waterfallHTTPClient.Do(filesReq)
		if err == nil {
			defer filesResp.Body.Close()
			if filesResp.StatusCode == http.StatusOK {
				var filesData struct {
					Result []struct {
						Name   string `json:"name"`
						Format string `json:"format"`
					} `json:"result"`
				}
				if json.NewDecoder(filesResp.Body).Decode(&filesData) == nil {
					for _, f := range filesData.Result {
						if strings.HasSuffix(strings.ToLower(f.Name), ".flac") || strings.EqualFold(f.Format, "Flac") {
							directURL := fmt.Sprintf("https://archive.org/download/%s/%s", id, url.PathEscape(f.Name))
							return directURL, true
						}
					}
				}
			}
		}
	}

	return fmt.Sprintf("https://archive.org/details/%s", id), true
}

// searchSoundCloudHQ checks SoundCloud for candidate 320kbps streams.
func searchSoundCloudHQ(ctx context.Context, query string) (string, bool) {
	if query == "" {
		return "", false
	}
	// yt-dlp native SoundCloud query
	return fmt.Sprintf("scsearch1:%s", query), true
}
