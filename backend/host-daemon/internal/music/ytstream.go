package music

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"sync"
)

var (
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

// HandleResolveStreamURL returns a JSON response containing the stream endpoint URL and starts caching.
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

	cacheDir := getCacheDir()
	_ = os.MkdirAll(cacheDir, 0755)
	cacheFilePath := filepath.Join(cacheDir, fmt.Sprintf("%s.mp4", id))

	// If not cached, initiate background download with independent context
	if stat, err := os.Stat(cacheFilePath); err != nil || stat.Size() <= 50000 {
		go func() {
			_ = downloadAndCache(context.Background(), id, cacheFilePath)
		}()
	}

	json.NewEncoder(w).Encode(map[string]any{
		"url":       fmt.Sprintf("/api/v1/music/ytstream/stream.m4a?id=%s", id),
		"is_cached": true,
	})
}

// HandleYTStream serves the audio stream directly from local disk cache with HTTP 206 Range support.
// If the track is not yet cached, it downloads it with yt-dlp first and then serves it progressively.
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

	// Validate YouTube video ID
	if len(id) > 30 || strings.ContainsAny(id, "/\\?%*:|\"<> ") {
		http.Error(w, "Invalid video id", http.StatusBadRequest)
		return
	}

	cacheDir := getCacheDir()
	_ = os.MkdirAll(cacheDir, 0755)
	cacheFilePath := filepath.Join(cacheDir, fmt.Sprintf("%s.mp4", id))

	// 1. If already saved to disk cache, serve directly with byte range seeking
	if stat, err := os.Stat(cacheFilePath); err == nil && stat.Size() > 50000 {
		serveCachedFile(w, r, cacheFilePath, stat)
		return
	}

	// 2. Not cached yet: download & cache cleanly using request context
	if err := downloadAndCache(r.Context(), id, cacheFilePath); err == nil {
		if stat, err := os.Stat(cacheFilePath); err == nil && stat.Size() > 50000 {
			serveCachedFile(w, r, cacheFilePath, stat)
			return
		}
	}

	http.Error(w, "Failed to fetch audio stream", http.StatusBadGateway)
}

func serveCachedFile(w http.ResponseWriter, r *http.Request, filePath string, stat os.FileInfo) {
	file, err := os.Open(filePath)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer file.Close()

	w.Header().Set("Content-Type", "audio/mp4")
	w.Header().Set("Accept-Ranges", "bytes")
	http.ServeContent(w, r, "stream.m4a", stat.ModTime(), file)
}

func downloadAndCache(parentCtx context.Context, id string, destPath string) error {
	lock := getFlightLock(id)
	lock.Lock()
	defer lock.Unlock()

	if stat, err := os.Stat(destPath); err == nil && stat.Size() > 50000 {
		return nil
	}

	tmpFile := destPath + ".tmp"
	_ = os.Remove(tmpFile)

	log.Printf("music ytstream: downloading & caching %s...", id)

	ctx, cancel := context.WithTimeout(parentCtx, defaultStreamTimeout)
	defer cancel()

	args := []string{
		"--js-runtimes", jsRuntimesArg(),
		"--no-warnings",
		"--no-check-certificates",
		"-f", "bestaudio[ext=m4a]/140/bestaudio/ba/b",
		"--no-playlist",
		"-o", tmpFile,
		"https://www.youtube.com/watch?v=" + id,
	}

	_, err := ExecYtDlp(ctx, "ytstream", id, args)
	if err != nil {
		_ = os.Remove(tmpFile)
		return err
	}

	if stat, err := os.Stat(tmpFile); err == nil && stat.Size() > 50000 {
		if err := os.Rename(tmpFile, destPath); err != nil {
			_ = os.Remove(tmpFile)
			return err
		}
		log.Printf("music ytstream: successfully cached %s (%d bytes)", id, stat.Size())
		return nil
	}

	_ = os.Remove(tmpFile)
	return fmt.Errorf("downloaded file invalid or too small")
}
