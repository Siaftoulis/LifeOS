package system

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"
)

const (
	githubRepo     = "Siaftoulis/LifeOS"
	cacheDuration  = 15 * time.Minute
	updatesDataDir = "./data/updates"
)

type ReleaseAsset struct {
	Name               string `json:"name"`
	BrowserDownloadURL string `json:"browser_download_url"`
	Size               int64  `json:"size"`
}

type GitHubReleaseResponse struct {
	TagName     string         `json:"tag_name"`
	Name        string         `json:"name"`
	Body        string         `json:"body"`
	PublishedAt string         `json:"published_at"`
	Assets      []ReleaseAsset `json:"assets"`
}

type ReleaseInfo struct {
	TagName     string    `json:"tag_name"`
	Title       string    `json:"title"`
	Body        string    `json:"body"`
	PublishedAt time.Time `json:"published_at"`
	BuildNumber int       `json:"build_number"`
	ApkURL      string    `json:"apk_url,omitempty"`
	ZipURL      string    `json:"zip_url,omitempty"`
	CachedApk   bool      `json:"cached_apk"`
	CachedZip   bool      `json:"cached_zip"`
}

var (
	cachedRelease     *ReleaseInfo
	cachedReleaseTime time.Time
	releaseMutex      sync.RWMutex
	downloadMutex     sync.Mutex
)

// ExtractBuildNumber parses build number from tag, body, or title
func extractBuildNumber(tag, title, body string) int {
	if strings.Contains(tag, "+") {
		parts := strings.Split(tag, "+")
		if n, err := strconv.Atoi(parts[len(parts)-1]); err == nil {
			return n
		}
	}

	buildRegex := regexp.MustCompile(`(?i)(?:Build\s*#|build_number[\s:]+)(\d+)`)
	if match := buildRegex.FindStringSubmatch(body); len(match) > 1 {
		if n, err := strconv.Atoi(match[1]); err == nil {
			return n
		}
	}

	titleRegex := regexp.MustCompile(`(?i)Build\s*#(\d+)`)
	if match := titleRegex.FindStringSubmatch(title); len(match) > 1 {
		if n, err := strconv.Atoi(match[1]); err == nil {
			return n
		}
	}

	digitsOnly := regexp.MustCompile(`\D`).ReplaceAllString(tag, "")
	if n, err := strconv.Atoi(digitsOnly); err == nil && n > 0 {
		return n
	}

	return 0
}

// GetLatestRelease returns cached or freshly fetched GitHub release metadata
func GetLatestRelease(forceRefresh bool) (*ReleaseInfo, error) {
	releaseMutex.RLock()
	if !forceRefresh && cachedRelease != nil && time.Since(cachedReleaseTime) < cacheDuration {
		rel := *cachedRelease
		releaseMutex.RUnlock()
		updateCacheFlags(&rel)
		return &rel, nil
	}
	releaseMutex.RUnlock()

	releaseMutex.Lock()
	defer releaseMutex.Unlock()

	if !forceRefresh && cachedRelease != nil && time.Since(cachedReleaseTime) < cacheDuration {
		rel := *cachedRelease
		updateCacheFlags(&rel)
		return &rel, nil
	}

	url := fmt.Sprintf("https://api.github.com/repos/%s/releases/latest", githubRepo)
	client := &http.Client{Timeout: 15 * time.Second}
	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		if cachedRelease != nil {
			return cachedRelease, nil
		}
		return nil, err
	}
	req.Header.Set("Accept", "application/vnd.github.v3+json")
	req.Header.Set("User-Agent", "LifeOS-HostDaemon")

	resp, err := client.Do(req)
	if err != nil {
		if cachedRelease != nil {
			log.Printf("[Updates] GitHub fetch failed, serving stale cache: %v", err)
			return cachedRelease, nil
		}
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		if cachedRelease != nil {
			log.Printf("[Updates] GitHub returned %d, serving stale cache", resp.StatusCode)
			return cachedRelease, nil
		}
		return nil, fmt.Errorf("GitHub API returned status %d", resp.StatusCode)
	}

	var ghResp GitHubReleaseResponse
	if err := json.NewDecoder(resp.Body).Decode(&ghResp); err != nil {
		return nil, err
	}

	var apkURL, zipURL string
	for _, asset := range ghResp.Assets {
		name := strings.ToLower(asset.Name)
		if strings.HasSuffix(name, ".apk") {
			apkURL = asset.BrowserDownloadURL
		} else if strings.HasSuffix(name, ".zip") {
			zipURL = asset.BrowserDownloadURL
		}
	}

	pubTime, _ := time.Parse(time.RFC3339, ghResp.PublishedAt)
	if pubTime.IsZero() {
		pubTime = time.Now()
	}

	title := ghResp.Name
	if title == "" {
		title = ghResp.TagName
	}

	rel := &ReleaseInfo{
		TagName:     ghResp.TagName,
		Title:       title,
		Body:        ghResp.Body,
		PublishedAt: pubTime,
		BuildNumber: extractBuildNumber(ghResp.TagName, title, ghResp.Body),
		ApkURL:      apkURL,
		ZipURL:      zipURL,
	}

	updateCacheFlags(rel)

	cachedRelease = rel
	cachedReleaseTime = time.Now()
	return rel, nil
}

func updateCacheFlags(rel *ReleaseInfo) {
	if rel == nil {
		return
	}
	apkFile := filepath.Join(updatesDataDir, fmt.Sprintf("lifeos-%s.apk", rel.TagName))
	if info, err := os.Stat(apkFile); err == nil && info.Size() > 1000000 {
		rel.CachedApk = true
	} else {
		rel.CachedApk = false
	}

	zipFile := filepath.Join(updatesDataDir, fmt.Sprintf("lifeos-%s.zip", rel.TagName))
	if info, err := os.Stat(zipFile); err == nil && info.Size() > 1000000 {
		rel.CachedZip = true
	} else {
		rel.CachedZip = false
	}
}

// DownloadAndCacheAsset ensures the specified asset (apk or zip) for a release is cached locally
func DownloadAndCacheAsset(rel *ReleaseInfo, assetType string) (string, error) {
	downloadMutex.Lock()
	defer downloadMutex.Unlock()

	if err := os.MkdirAll(updatesDataDir, 0755); err != nil {
		return "", err
	}

	ext := "apk"
	downloadURL := rel.ApkURL
	if assetType == "zip" || assetType == "windows" {
		ext = "zip"
		downloadURL = rel.ZipURL
	}

	if downloadURL == "" {
		return "", fmt.Errorf("no download URL found for asset type %s", assetType)
	}

	targetPath := filepath.Join(updatesDataDir, fmt.Sprintf("lifeos-%s.%s", rel.TagName, ext))
	if info, err := os.Stat(targetPath); err == nil && info.Size() > 1000000 {
		return targetPath, nil
	}

	partPath := targetPath + ".part"
	_ = os.Remove(partPath)

	log.Printf("[Updates] Downloading %s asset from GitHub: %s", assetType, downloadURL)
	client := &http.Client{Timeout: 10 * time.Minute}
	req, err := http.NewRequest(http.MethodGet, downloadURL, nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("User-Agent", "LifeOS-HostDaemon")

	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("GitHub download returned status %d", resp.StatusCode)
	}

	out, err := os.Create(partPath)
	if err != nil {
		return "", err
	}

	_, err = io.Copy(out, resp.Body)
	_ = out.Close()
	if err != nil {
		_ = os.Remove(partPath)
		return "", err
	}

	if info, err := os.Stat(partPath); err != nil || info.Size() < 1000000 {
		_ = os.Remove(partPath)
		return "", fmt.Errorf("downloaded file is invalid or too small")
	}

	_ = os.Remove(targetPath)
	if err := os.Rename(partPath, targetPath); err != nil {
		return "", err
	}

	log.Printf("[Updates] Successfully cached %s at %s", assetType, targetPath)
	return targetPath, nil
}
