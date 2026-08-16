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
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, HEAD, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

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
			"url":       fmt.Sprintf("/api/v1/music/ytstream/stream.m4a?id=%s", id),
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
		"-f", "bestaudio[ext=m4a]/bestaudio/ba/b",
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

// HandleYTStream serves the stream directly from local SSD disk cache or proxies from CDN.
func HandleYTStream(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, HEAD, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "*")
	w.Header().Set("Access-Control-Expose-Headers", "Content-Length, Content-Range, Accept-Ranges, Content-Type")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

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
		file, err := os.Open(cacheFilePath)
		if err == nil {
			defer file.Close()
			w.Header().Set("Accept-Ranges", "bytes")
			w.Header().Set("Content-Type", "audio/mp4")
			http.ServeContent(w, r, "stream.m4a", stat.ModTime(), file)
			return
		}
	}

	// 2. Check in-memory CDN URL cache
	urlCacheMu.RLock()
	cached, exists := urlCache[id]
	urlCacheMu.RUnlock()

	var streamURL string
	if exists && time.Now().Before(cached.expiresAt) {
		streamURL = cached.url
	} else {
		// 3. Resolve direct YouTube audio stream URL via yt-dlp -g
		log.Printf("music ytstream: resolving direct audio URL for %s...", id)
		cmd := exec.Command("yt-dlp",
			"--js-runtimes", "node:C:\\Program Files\\nodejs\\node.exe,node,bun",
			"--extractor-args", "youtube:player_client=mweb,web,ios,android,tv",
			"--no-warnings",
			"--no-check-certificates",
			"-f", "bestaudio[ext=m4a]/bestaudio/ba/b",
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

		streamURL = strings.TrimSpace(lines[0])

		urlCacheMu.Lock()
		urlCache[id] = streamCacheEntry{
			url:       streamURL,
			expiresAt: time.Now().Add(3 * time.Hour),
		}
		urlCacheMu.Unlock()
	}

	// Trigger background disk caching for offline & future instant replays
	go maybeCacheInBackground(id, cacheFilePath)

	// Proxy stream with Range and CORS support
	proxyStream(w, r, streamURL)
}

func proxyStream(w http.ResponseWriter, r *http.Request, targetURL string) {
	isHead := r.Method == http.MethodHead
	httpMethod := http.MethodGet

	req, err := http.NewRequestWithContext(r.Context(), httpMethod, targetURL, nil)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if isHead {
		req.Header.Set("Range", "bytes=0-0")
	} else if rangeHdr := r.Header.Get("Range"); rangeHdr != "" {
		req.Header.Set("Range", rangeHdr)
	}
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

	client := &http.Client{Timeout: 0}
	resp, err := client.Do(req)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, HEAD, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "*")
	w.Header().Set("Access-Control-Expose-Headers", "Content-Length, Content-Range, Accept-Ranges, Content-Type")
	w.Header().Set("Accept-Ranges", "bytes")

	if ct := resp.Header.Get("Content-Type"); ct != "" {
		w.Header().Set("Content-Type", ct)
	} else {
		w.Header().Set("Content-Type", "audio/webm")
	}
	if cl := resp.Header.Get("Content-Length"); cl != "" && !isHead {
		w.Header().Set("Content-Length", cl)
	}
	if cr := resp.Header.Get("Content-Range"); cr != "" {
		w.Header().Set("Content-Range", cr)
	}
	if lm := resp.Header.Get("Last-Modified"); lm != "" {
		w.Header().Set("Last-Modified", lm)
	}

	statusCode := resp.StatusCode
	if isHead && statusCode == http.StatusPartialContent {
		statusCode = http.StatusOK
	}
	w.WriteHeader(statusCode)

	if isHead {
		return
	}

	buf := make([]byte, 64*1024)
	for {
		n, rErr := resp.Body.Read(buf)
		if n > 0 {
			if _, wErr := w.Write(buf[:n]); wErr != nil {
				return
			}
			if f, ok := w.(http.Flusher); ok {
				f.Flush()
			}
		}
		if rErr != nil {
			break
		}
	}
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
		"-f", "bestaudio[ext=m4a]/bestaudio/ba/b",
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