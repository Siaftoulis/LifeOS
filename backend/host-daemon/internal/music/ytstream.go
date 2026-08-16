package music

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

type streamCacheEntry struct {
	url       string
	expiresAt time.Time
}

var (
	urlCacheMu sync.RWMutex
	urlCache   = make(map[string]streamCacheEntry)

	flightMu   sync.Mutex
	flightLock = make(map[string]*sync.Mutex)
)

func getFlightLock(id string) *sync.Mutex {
	flightMu.Lock()
	defer flightMu.Unlock()
	if lock, exists := flightLock[id]; exists {
		return lock
	}
	lock := &sync.Mutex{}
	flightLock[id] = lock
	return lock
}

// HandleResolveStreamURL returns a JSON response containing the direct, playable stream URL.
// Calling this endpoint ensures the client receives a 100% prepared stream URL before calling the player engine.
func HandleResolveStreamURL(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	id := strings.TrimSpace(r.URL.Query().Get("id"))
	if id == "" {
		http.Error(w, `{"error":"Missing video id"}`, http.StatusBadRequest)
		return
	}

	cacheDir := filepath.Join("data", "music_cache")
	_ = os.MkdirAll(cacheDir, 0755)
	cacheFilePath := filepath.Join(cacheDir, fmt.Sprintf("%s.mp4", id))

	// 1. If already saved to disk cache, serve directly with byte range seeking
	if stat, err := os.Stat(cacheFilePath); err == nil && stat.Size() > 50000 {
		json.NewEncoder(w).Encode(map[string]any{
			"url":       fmt.Sprintf("http://localhost:50051/api/v1/music/ytstream/stream.m4a?id=%s", id),
			"is_cached": true,
		})
		return
	}

	// 2. Check in-memory CDN URL cache
	urlCacheMu.RLock()
	cached, exists := urlCache[id]
	urlCacheMu.RUnlock()

	if exists && time.Now().Before(cached.expiresAt) {
		json.NewEncoder(w).Encode(map[string]any{
			"url":       cached.url,
			"is_cached": false,
		})
		go maybeCacheInBackground(id, cacheFilePath)
		return
	}

	// 3. Resolve direct YouTube audio stream URL via yt-dlp -g
	log.Printf("music ytstream: resolving direct audio URL for %s...", id)
	cmd := exec.Command("yt-dlp",
		"--js-runtimes", "node:C:\\Program Files\\nodejs\\node.exe,node,bun",
		"--extractor-args", "youtube:player_client=mweb,web,ios,android,tv",
		"--no-warnings",
		"--no-check-certificates",
		"-f", "bestaudio/18/ba/b/best",
		"-g",
		"https://www.youtube.com/watch?v="+id,
	)

	out, err := cmd.Output()
	if err != nil {
		log.Printf("music ytstream: failed to resolve stream for %s: %v", id, err)
		http.Error(w, `{"error":"Failed to resolve stream URL"}`, http.StatusBadGateway)
		return
	}

	raw := strings.TrimSpace(string(out))
	lines := strings.Split(raw, "\n")
	if len(lines) == 0 || lines[0] == "" {
		http.Error(w, `{"error":"Empty stream URL resolved"}`, http.StatusBadGateway)
		return
	}

	streamURL := strings.TrimSpace(lines[0])

	// Cache URL for 3 hours
	urlCacheMu.Lock()
	urlCache[id] = streamCacheEntry{
		url:       streamURL,
		expiresAt: time.Now().Add(3 * time.Hour),
	}
	urlCacheMu.Unlock()

	json.NewEncoder(w).Encode(map[string]any{
		"url":       streamURL,
		"is_cached": false,
	})

	// Trigger background disk caching for offline & future instant replays
	go maybeCacheInBackground(id, cacheFilePath)
}

// HandleYTStream serves the stream directly from local SSD disk cache or redirects to CDN.
func HandleYTStream(w http.ResponseWriter, r *http.Request) {
	id := strings.TrimSpace(r.URL.Query().Get("id"))
	if id == "" {
		http.Error(w, "Missing video id", http.StatusBadRequest)
		return
	}

	cacheDir := filepath.Join("data", "music_cache")
	_ = os.MkdirAll(cacheDir, 0755)
	cacheFilePath := filepath.Join(cacheDir, fmt.Sprintf("%s.mp4", id))

	// 1. If already saved to disk cache, serve directly with byte range seeking
	if stat, err := os.Stat(cacheFilePath); err == nil && stat.Size() > 50000 {
		w.Header().Set("Accept-Ranges", "bytes")
		http.ServeFile(w, r, cacheFilePath)
		return
	}

	// 2. Check in-memory CDN URL cache
	urlCacheMu.RLock()
	cached, exists := urlCache[id]
	urlCacheMu.RUnlock()

	if exists && time.Now().Before(cached.expiresAt) {
		http.Redirect(w, r, cached.url, http.StatusFound)
		go maybeCacheInBackground(id, cacheFilePath)
		return
	}

	// 3. Resolve direct YouTube audio stream URL via yt-dlp -g
	log.Printf("music ytstream: resolving direct audio URL for %s...", id)
	cmd := exec.Command("yt-dlp",
		"--js-runtimes", "node:C:\\Program Files\\nodejs\\node.exe,node,bun",
		"--extractor-args", "youtube:player_client=mweb,web,ios,android,tv",
		"--no-warnings",
		"--no-check-certificates",
		"-f", "bestaudio/18/ba/b/best",
		"-g",
		"https://www.youtube.com/watch?v="+id,
	)

	out, err := cmd.Output()
	if err != nil {
		log.Printf("music ytstream: failed to resolve stream for %s: %v", id, err)
		http.Error(w, "Failed to resolve stream URL", http.StatusBadGateway)
		return
	}

	raw := strings.TrimSpace(string(out))
	lines := strings.Split(raw, "\n")
	if len(lines) == 0 || lines[0] == "" {
		http.Error(w, "Empty stream URL resolved", http.StatusBadGateway)
		return
	}

	streamURL := strings.TrimSpace(lines[0])

	// Cache URL for 3 hours
	urlCacheMu.Lock()
	urlCache[id] = streamCacheEntry{
		url:       streamURL,
		expiresAt: time.Now().Add(3 * time.Hour),
	}
	urlCacheMu.Unlock()

	// Redirect client (MPV / media_kit) directly to CDN
	http.Redirect(w, r, streamURL, http.StatusFound)

	// Trigger background disk caching for offline & future instant replays
	go maybeCacheInBackground(id, cacheFilePath)
}

func maybeCacheInBackground(id string, destPath string) {
	lock := getFlightLock(id)
	if !lock.TryLock() {
		return // Already downloading in another worker
	}
	defer lock.Unlock()

	if stat, err := os.Stat(destPath); err == nil && stat.Size() > 50000 {
		return
	}

	tmpFile := destPath + ".tmp"
	_ = os.Remove(tmpFile)

	log.Printf("music ytstream: caching %s to disk in background...", id)
	cmd := exec.Command("yt-dlp",
		"--js-runtimes", "node:C:\\Program Files\\nodejs\\node.exe,node,bun",
		"--extractor-args", "youtube:player_client=mweb,web,ios,android,tv",
		"--no-warnings",
		"--no-check-certificates",
		"-f", "bestaudio/18/ba/b/best",
		"--no-playlist",
		"-o", tmpFile,
		"https://www.youtube.com/watch?v="+id,
	)

	if err := cmd.Run(); err != nil {
		log.Printf("music ytstream: background cache failed for %s: %v", id, err)
		_ = os.Remove(tmpFile)
		return
	}

	if stat, err := os.Stat(tmpFile); err == nil && stat.Size() > 50000 {
		_ = os.Rename(tmpFile, destPath)
		log.Printf("music ytstream: successfully cached %s (%d bytes)", id, stat.Size())
	} else {
		_ = os.Remove(tmpFile)
	}
}