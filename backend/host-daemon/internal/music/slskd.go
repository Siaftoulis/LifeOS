package music

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// SlskdClient connects to a local or remote slskd (Soulseek daemon) instance.
type SlskdClient struct {
	BaseURL    string
	APIKey     string
	HTTPClient *http.Client
}

// SlskdFileMatch represents a candidate lossless audio file on the Soulseek network.
type SlskdFileMatch struct {
	Username   string `json:"username"`
	Filename   string `json:"filename"`
	Size       int64  `json:"size"`
	BitRate    int    `json:"bitrate"`
	SampleRate int    `json:"sample_rate"`
	BitDepth   int    `json:"bit_depth"`
	SlotsFree  bool   `json:"slots_free"`
	Speed      int64  `json:"speed"`
}

// NewSlskdClient creates a new client referencing SLSKD_URL (default: http://localhost:5030).
func NewSlskdClient() *SlskdClient {
	baseURL := GetMusicConfig("slskd_url")
	if baseURL == "" {
		baseURL = os.Getenv("SLSKD_URL")
	}
	if baseURL == "" {
		baseURL = "http://localhost:5030"
	}
	baseURL = strings.TrimRight(baseURL, "/")

	apiKey := GetMusicConfig("slskd_api_key")
	if apiKey == "" {
		apiKey = os.Getenv("SLSKD_API_KEY")
	}

	return &SlskdClient{
		BaseURL: baseURL,
		APIKey:  apiKey,
		HTTPClient: &http.Client{
			Timeout: 4 * time.Second,
		},
	}
}

// IsAvailable checks whether the slskd service is alive and answering API queries.
func (c *SlskdClient) IsAvailable(ctx context.Context) bool {
	probeCtx, cancel := context.WithTimeout(ctx, 800*time.Millisecond)
	defer cancel()

	req, err := http.NewRequestWithContext(probeCtx, http.MethodGet, c.BaseURL+"/api/v0/session", nil)
	if err != nil {
		return false
	}
	if c.APIKey != "" {
		req.Header.Set("X-API-KEY", c.APIKey)
	}

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return false
	}
	defer resp.Body.Close()

	return resp.StatusCode == http.StatusOK || resp.StatusCode == http.StatusUnauthorized
}

// SearchFLAC searches the Soulseek network for a FLAC release of the specified artist and title.
func (c *SlskdClient) SearchFLAC(ctx context.Context, artist, title string) (*SlskdFileMatch, error) {
	if !c.IsAvailable(ctx) {
		return nil, fmt.Errorf("slskd daemon not available at %s", c.BaseURL)
	}

	searchQuery := fmt.Sprintf("%s %s flac", artist, title)
	payload, err := json.Marshal(map[string]string{
		"searchText": searchQuery,
	})
	if err != nil {
		return nil, err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.BaseURL+"/api/v0/searches", bytes.NewReader(payload))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	if c.APIKey != "" {
		req.Header.Set("X-API-KEY", c.APIKey)
	}

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusCreated {
		return nil, fmt.Errorf("slskd search initiation failed: status %d", resp.StatusCode)
	}

	var searchInit struct {
		ID string `json:"id"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&searchInit); err != nil || searchInit.ID == "" {
		return nil, fmt.Errorf("failed to parse slskd search ID: %v", err)
	}

	// Poll search results for up to 3 seconds for fast candidate resolution
	deadline := time.Now().Add(3 * time.Second)
	for time.Now().Before(deadline) {
		select {
		case <-ctx.Done():
			return nil, ctx.Err()
		case <-time.After(600 * time.Millisecond):
		}

		match, err := c.fetchSearchResults(ctx, searchInit.ID, artist, title)
		if err == nil && match != nil {
			return match, nil
		}
	}

	return nil, fmt.Errorf("no matching lossless FLAC found on Soulseek network for %s - %s", artist, title)
}

func (c *SlskdClient) fetchSearchResults(ctx context.Context, searchID, artist, title string) (*SlskdFileMatch, error) {
	reqURL := fmt.Sprintf("%s/api/v0/searches/%s/responses", c.BaseURL, url.PathEscape(searchID))
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, reqURL, nil)
	if err != nil {
		return nil, err
	}
	if c.APIKey != "" {
		req.Header.Set("X-API-KEY", c.APIKey)
	}

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("slskd responses returned %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var responses []struct {
		Username    string `json:"username"`
		UploadSpeed int64  `json:"uploadSpeed"`
		FreeUploadSlots int `json:"freeUploadSlots"`
		Files       []struct {
			Filename   string `json:"filename"`
			Size       int64  `json:"size"`
			BitRate    int    `json:"bitRate"`
			SampleRate int    `json:"sampleRate"`
			BitDepth   int    `json:"bitDepth"`
			Extension  string `json:"extension"`
		} `json:"files"`
	}

	if err := json.Unmarshal(body, &responses); err != nil {
		return nil, err
	}

	artistLower := strings.ToLower(artist)
	titleLower := strings.ToLower(title)

	var bestMatch *SlskdFileMatch

	for _, userResp := range responses {
		for _, file := range userResp.Files {
			ext := strings.ToLower(filepath.Ext(file.Filename))
			if ext != ".flac" && !strings.EqualFold(file.Extension, "flac") {
				continue
			}

			fnLower := strings.ToLower(file.Filename)
			// Ensure both artist and title appear in the filename or directory path
			if !strings.Contains(fnLower, artistLower) || !strings.Contains(fnLower, titleLower) {
				continue
			}

			hasSlots := userResp.FreeUploadSlots > 0
			candidate := &SlskdFileMatch{
				Username:   userResp.Username,
				Filename:   file.Filename,
				Size:       file.Size,
				BitRate:    file.BitRate,
				SampleRate: file.SampleRate,
				BitDepth:   file.BitDepth,
				SlotsFree:  hasSlots,
				Speed:      userResp.UploadSpeed,
			}

			if bestMatch == nil {
				bestMatch = candidate
			} else if hasSlots && !bestMatch.SlotsFree {
				bestMatch = candidate
			} else if hasSlots == bestMatch.SlotsFree && candidate.Speed > bestMatch.Speed {
				bestMatch = candidate
			}
		}
	}

	return bestMatch, nil
}

// EnqueueDownload queues a file for download from a Soulseek peer.
func (c *SlskdClient) EnqueueDownload(ctx context.Context, match *SlskdFileMatch) error {
	reqURL := fmt.Sprintf("%s/api/v0/transfers/downloads/%s", c.BaseURL, url.PathEscape(match.Username))
	payload, err := json.Marshal([]map[string]interface{}{
		{
			"filename": match.Filename,
			"size":     match.Size,
		},
	})
	if err != nil {
		return err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, reqURL, bytes.NewReader(payload))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	if c.APIKey != "" {
		req.Header.Set("X-API-KEY", c.APIKey)
	}

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		return fmt.Errorf("slskd download queue failed: status %d", resp.StatusCode)
	}

	log.Printf("slskd: queued peer download: user=%s file=%s (size=%d)", match.Username, match.Filename, match.Size)
	return nil
}
