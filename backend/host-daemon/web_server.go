package main

import (
	"fmt"
	"mime"
	"net/http"
	"os"
	"path/filepath"
	"strings"
)

func init() {
	// Ensure WebAssembly and modern web MIME types are recognized
	_ = mime.AddExtensionType(".wasm", "application/wasm")
	_ = mime.AddExtensionType(".js", "application/javascript")
	_ = mime.AddExtensionType(".json", "application/json")
	_ = mime.AddExtensionType(".css", "text/css; charset=utf-8")
	_ = mime.AddExtensionType(".svg", "image/svg+xml")
}

// newWebPortalHandler creates an optimized static file handler for Flutter Web.
// 1. Serves pre-compressed (.gz) static assets directly from disk with ZERO CPU overhead.
// 2. Implements smart HTTP caching (re-validation for index.html, 7-day cache for static assets).
// 3. Fallback to index.html for SPA client-side routing.
func newWebPortalHandler(webDir string) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		cleanPath := filepath.Clean(strings.TrimPrefix(r.URL.Path, "/"))
		fullPath := filepath.Join(webDir, cleanPath)

		// Check if file exists; if not found or is a directory, look for index.html
		info, err := os.Stat(fullPath)
		isIndex := false
		if err != nil || info.IsDir() {
			if info != nil && info.IsDir() {
				indexPath := filepath.Join(fullPath, "index.html")
				if indexInfo, errIdx := os.Stat(indexPath); errIdx == nil {
					fullPath = indexPath
					info = indexInfo
					isIndex = true
				}
			}
			if !isIndex {
				indexPath := filepath.Join(webDir, "index.html")
				if indexInfo, errIdx := os.Stat(indexPath); errIdx == nil {
					fullPath = indexPath
					info = indexInfo
					isIndex = true
					r.URL.Path = "/"
				} else {
					http.NotFound(w, r)
					return
				}
			}
		} else if cleanPath == "index.html" || cleanPath == "" || cleanPath == "." {
			isIndex = true
		}

		// Smart Caching Headers
		if isIndex {
			// index.html: always check for fresh releases, but allow 304 Not Modified via ETag
			etag := fmt.Sprintf(`W/"%x-%x"`, info.ModTime().Unix(), info.Size())
			w.Header().Set("ETag", etag)
			w.Header().Set("Cache-Control", "no-cache, must-revalidate")
			if match := r.Header.Get("If-None-Match"); match != "" && (match == etag || match == "*") {
				w.WriteHeader(http.StatusNotModified)
				return
			}
		} else {
			// Static assets (main.dart.js, canvaskit.wasm, fonts, icons, etc.)
			etag := fmt.Sprintf(`"%x-%x"`, info.ModTime().Unix(), info.Size())
			w.Header().Set("ETag", etag)
			w.Header().Set("Cache-Control", "public, max-age=604800, stale-while-revalidate=86400")
			if match := r.Header.Get("If-None-Match"); match != "" && (match == etag || match == "*") {
				w.WriteHeader(http.StatusNotModified)
				return
			}
		}

		// Check if client accepts gzip and if a pre-compressed .gz file exists on disk
		if strings.Contains(r.Header.Get("Accept-Encoding"), "gzip") {
			gzPath := fullPath + ".gz"
			if gzInfo, errGz := os.Stat(gzPath); errGz == nil && !gzInfo.IsDir() {
				ext := strings.ToLower(filepath.Ext(fullPath))
				contentType := mime.TypeByExtension(ext)
				if contentType == "" {
					contentType = "application/octet-stream"
				}
				w.Header().Set("Content-Type", contentType)
				w.Header().Set("Content-Encoding", "gzip")
				w.Header().Set("Vary", "Accept-Encoding")
				http.ServeFile(w, r, gzPath)
				return
			}
		}

		// Fallback: serve raw uncompressed file
		http.ServeFile(w, r, fullPath)
	})
}
