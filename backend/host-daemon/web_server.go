package main

import (
	"compress/gzip"
	"fmt"
	"io"
	"mime"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"sync"
)

func init() {
	// Ensure WebAssembly and modern web MIME types are recognized
	_ = mime.AddExtensionType(".wasm", "application/wasm")
	_ = mime.AddExtensionType(".js", "application/javascript")
	_ = mime.AddExtensionType(".json", "application/json")
	_ = mime.AddExtensionType(".css", "text/css; charset=utf-8")
	_ = mime.AddExtensionType(".svg", "image/svg+xml")
}

// gzipResponseWriter wraps http.ResponseWriter to compress output with gzip.
type gzipResponseWriter struct {
	io.Writer
	http.ResponseWriter
	wroteHeader bool
}

func (w *gzipResponseWriter) WriteHeader(status int) {
	if w.wroteHeader {
		return
	}
	w.wroteHeader = true
	// Delete Content-Length because compression changes the payload size
	w.ResponseWriter.Header().Del("Content-Length")
	w.ResponseWriter.Header().Set("Content-Encoding", "gzip")
	w.ResponseWriter.Header().Add("Vary", "Accept-Encoding")
	w.ResponseWriter.WriteHeader(status)
}

func (w *gzipResponseWriter) Write(b []byte) (int, error) {
	if !w.wroteHeader {
		w.WriteHeader(http.StatusOK)
	}
	return w.Writer.Write(b)
}

var gzPool = sync.Pool{
	New: func() interface{} {
		w, _ := gzip.NewWriterLevel(io.Discard, gzip.DefaultCompression)
		return w
	},
}

// newWebPortalHandler creates an optimized static file handler for the Flutter Web portal.
// It provides:
// 1. Transparent Gzip compression for text, JavaScript, WebAssembly, and font assets.
// 2. Smart HTTP Caching: fresh check for index.html with ETags, 7-day caching for static assets.
// 3. SPA Fallback: non-API routes fallback to index.html for client-side routing.
func newWebPortalHandler(webDir string) http.Handler {
	fileServer := http.FileServer(http.Dir(webDir))

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		cleanPath := filepath.Clean(strings.TrimPrefix(r.URL.Path, "/"))
		fullPath := filepath.Join(webDir, cleanPath)

		// Check if file exists; if not found or is a directory without index, fallback to index.html
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
					// Internal rewrite for SPA fallback
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

		// Check for Gzip compression support
		ext := strings.ToLower(filepath.Ext(fullPath))
		compressible := ext == ".js" || ext == ".wasm" || ext == ".html" || ext == ".css" ||
			ext == ".json" || ext == ".svg" || ext == ".ttf" || ext == ".woff" || ext == ".woff2"

		if compressible && strings.Contains(r.Header.Get("Accept-Encoding"), "gzip") {
			gz := gzPool.Get().(*gzip.Writer)
			defer gzPool.Put(gz)
			gz.Reset(w)
			defer gz.Close()

			gzw := &gzipResponseWriter{
				Writer:         gz,
				ResponseWriter: w,
			}
			fileServer.ServeHTTP(gzw, r)
			return
		}

		fileServer.ServeHTTP(w, r)
	})
}
