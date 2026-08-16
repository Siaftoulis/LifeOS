package sources

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"
)

// Result is one normalized hit from a single book source.
type Result struct {
	Source      string `json:"source"`
	Title       string `json:"title"`
	Author      string `json:"author"`
	Format      string `json:"format"`
	Size        string `json:"size"`
	Cover       string `json:"cover"`
	DownloadURL string `json:"download_url"`
	Confidence  int    `json:"confidence"`
}

type searcher func(ctx context.Context, query string) []Result

var searchTimeout = 12 * time.Second

// disabled reports whether a source is turned off via BOOKS_DISABLE_SOURCES
// (comma-separated names: gutenberg,openlibrary,mangadex,annas).
func disabled(name string) bool {
	for _, s := range strings.Split(os.Getenv("BOOKS_DISABLE_SOURCES"), ",") {
		if strings.TrimSpace(s) == name {
			return true
		}
	}
	return false
}

// Search runs all enabled sources in parallel and merges the results.
func Search(ctx context.Context, query string) []Result {
	sources := []struct {
		name string
		fn   searcher
	}{
		{"gutenberg", searchGutenberg},
		{"openlibrary", searchOpenLibrary},
		{"mangadex", searchMangaDex},
		{"annas", searchAnnas},
	}
	ctx, cancel := context.WithTimeout(ctx, searchTimeout)
	defer cancel()

	var mu sync.Mutex
	var results []Result
	var wg sync.WaitGroup
	for _, s := range sources {
		if disabled(s.name) {
			continue
		}
		wg.Add(1)
		go func(s struct {
			name string
			fn   searcher
		}) {
			defer wg.Done()
			for _, r := range s.fn(ctx, query) {
				mu.Lock()
				results = append(results, r)
				mu.Unlock()
			}
		}(s)
	}
	wg.Wait()
	return results
}

// getJSON fetches url and decodes the JSON body into dst.
func getJSON(ctx context.Context, url string, dst any) error {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return err
	}
	req.Header.Set("User-Agent", "LifeOS-host-daemon/1.0")
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("status %d", resp.StatusCode)
	}
	return json.NewDecoder(resp.Body).Decode(dst)
}

// getPage fetches url and returns the raw body (bounded to 8MB).
func getPage(ctx context.Context, url string) (string, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("User-Agent", "Mozilla/5.0 (LifeOS host daemon; self-hosted)")
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("status %d", resp.StatusCode)
	}
	body, err := io.ReadAll(io.LimitReader(resp.Body, 8*1024*1024))
	if err != nil {
		return "", err
	}
	return string(body), nil
}