package music

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"
)

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

	stream, err := ResolveAudioStream(r.Context(), id)
	if err != nil {
		log.Printf("music ytstream resolve %s error: %v", id, err)
		http.Error(w, fmt.Sprintf(`{"error":%q}`, err.Error()), http.StatusBadGateway)
		return
	}

	title := strings.TrimSpace(r.URL.Query().Get("title"))
	artist := strings.TrimSpace(r.URL.Query().Get("artist"))

	var enrichedCover, enrichedAlbum, enrichedGenre string
	var enrichedYear int

	// 1. Check local SQLite DB first
	if DB != nil {
		_ = DB.QueryRowContext(r.Context(),
			"SELECT album, genre, year, COALESCE(NULLIF(thumbnail, ''), thumbnail_url, '') FROM music_tracks WHERE id = ? OR yt_dlp_id = ? LIMIT 1",
			id, id,
		).Scan(&enrichedAlbum, &enrichedGenre, &enrichedYear, &enrichedCover)
	}

	// 2. Query Deezer/iTunes concurrent enrichment if tags are missing and title/artist provided
	if (enrichedCover == "" || enrichedGenre == "") && (title != "" || artist != "") {
		enrichCtx, cancel := context.WithTimeout(r.Context(), 1500*time.Millisecond)
		meta := EnrichMetadata(enrichCtx, title, artist)
		cancel()
		if meta.CoverArtURL != "" && enrichedCover == "" {
			enrichedCover = meta.CoverArtURL
		}
		if meta.Album != "" && enrichedAlbum == "" {
			enrichedAlbum = meta.Album
		}
		if meta.Genre != "" && enrichedGenre == "" {
			enrichedGenre = meta.Genre
		}
		if meta.Year > 0 && enrichedYear == 0 {
			enrichedYear = meta.Year
		}
	}

	resp := map[string]any{
		"url":         fmt.Sprintf("/api/v1/music/ytstream/stream.m4a?id=%s&proxy=true", id),
		"direct_url":  stream.URL,
		"stream_type": stream.StreamType,
		"bitrate":     stream.Bitrate,
		"itag":        stream.Itag,
		"is_cached":   true,
	}
	if enrichedCover != "" {
		resp["cover_art_url"] = enrichedCover
	}
	if enrichedAlbum != "" {
		resp["album"] = enrichedAlbum
	}
	if enrichedGenre != "" {
		resp["genre"] = enrichedGenre
	}
	if enrichedYear > 0 {
		resp["year"] = enrichedYear
	}

	json.NewEncoder(w).Encode(resp)
}

// HandleYTStream serves the audio stream. If locally archived/downloaded on disk, serves with 206 Range.
// Otherwise, it immediately resolves the direct signed stream URL and proxies with 206 Range audio headers,
// completely eliminating yt-dlp CLI subprocess execution and GoogleVideo IP-binding failures on clients.
func HandleYTStream(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, HEAD, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "*")
	w.Header().Set("Access-Control-Expose-Headers", "Content-Length, Content-Range, Accept-Ranges, Content-Type")
	w.Header().Set("Cache-Control", "no-cache, no-store, must-revalidate")
	w.Header().Set("Pragma", "no-cache")
	w.Header().Set("Expires", "0")

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

	// 1. If saved to local disk (e.g. offline downloaded), serve directly with byte range seeking
	if stat, err := os.Stat(cacheFilePath); err == nil && stat.Size() > 50000 {
		serveCachedFile(w, r, cacheFilePath, stat)
		return
	}

	// 2. Resolve direct signed audio stream URL via in-memory cache/bridge (Zero CLI subprocesses)
	stream, err := ResolveAudioStream(r.Context(), id)
	if err != nil {
		log.Printf("music ytstream %s failed to resolve: %v", id, err)
		http.Error(w, "Failed to fetch audio stream", http.StatusBadGateway)
		return
	}

	// 3. Default: Always stream through reverse proxy to avoid GoogleVideo IP-binding 403 Forbidden.
	// Only redirect if client explicitly requests direct redirect via ?redirect=true
	if r.URL.Query().Get("redirect") == "true" {
		http.Redirect(w, r, stream.URL, http.StatusTemporaryRedirect)
		return
	}

	proxyLiveAudio(w, r, stream.URL)
}

func proxyLiveAudio(w http.ResponseWriter, r *http.Request, directURL string) {
	outReq, err := http.NewRequestWithContext(r.Context(), r.Method, directURL, nil)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	outReq.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36")
	if rangeHeader := r.Header.Get("Range"); rangeHeader != "" {
		outReq.Header.Set("Range", rangeHeader)
	}

	resp, err := http.DefaultClient.Do(outReq)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	for k, v := range resp.Header {
		w.Header()[k] = v
	}

	// Explicitly ensure CORS & byte-range streaming headers are set for web browsers
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, HEAD, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "*")
	w.Header().Set("Access-Control-Expose-Headers", "Content-Length, Content-Range, Accept-Ranges, Content-Type")
	w.Header().Set("Accept-Ranges", "bytes")

	// Crucial: Override video/mp4 or video/webm to audio/* MIME types
	// HTML5 <audio> / just_audio_web / ExoPlayer / media_kit expect audio container types
	ct := resp.Header.Get("Content-Type")
	if strings.HasPrefix(ct, "video/mp4") || ct == "" || strings.HasPrefix(ct, "application/") {
		w.Header().Set("Content-Type", "audio/mp4")
	} else if strings.HasPrefix(ct, "video/webm") {
		w.Header().Set("Content-Type", "audio/webm")
	}

	w.WriteHeader(resp.StatusCode)
	if r.Method != http.MethodHead {
		io.Copy(w, resp.Body)
	}
}

func serveCachedFile(w http.ResponseWriter, r *http.Request, filePath string, stat os.FileInfo) {
	file, err := os.Open(filePath)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer file.Close()

	// Sniff first 512 bytes for exact audio container to prevent extractor mismatch
	buf := make([]byte, 512)
	n, _ := file.Read(buf)
	_, _ = file.Seek(0, 0) // rewind

	contentType := "audio/mp4"
	if n >= 4 {
		if bytes.HasPrefix(buf, []byte("\x1a\x45\xdf\xa3")) {
			contentType = "audio/webm; codecs=\"opus\""
		} else if bytes.HasPrefix(buf, []byte("ID3")) || (buf[0] == 0xff && (buf[1]&0xe0) == 0xe0) {
			contentType = "audio/mpeg"
		} else if n >= 8 && (string(buf[4:8]) == "ftyp" || bytes.Contains(buf[:n], []byte("ftyp"))) {
			contentType = "audio/mp4"
		}
	}

	w.Header().Set("Content-Type", contentType)
	w.Header().Set("Accept-Ranges", "bytes")
	http.ServeContent(w, r, filepath.Base(filePath), stat.ModTime(), file)
}
