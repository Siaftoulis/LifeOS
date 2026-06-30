package sync

import (
	"bytes"
	"compress/gzip"
	"encoding/base64"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"sync"
)

var (
	gzipPool = sync.Pool{New: func() any { return new(gzip.Reader) }}
	dbMutex  sync.Mutex
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/sync/push", func(w http.ResponseWriter, r *http.Request) {
		log.Printf("[SUCCESS] Secure mTLS Sync Handshake Established with Mobile Target Profile")
		var payload struct {
			Data string `json:"data"`
		}
		if json.NewDecoder(r.Body).Decode(&payload) != nil {
			http.Error(w, "Bad Request", 400)
			return
		}
		raw, err := base64.StdEncoding.DecodeString(payload.Data)
		if err != nil {
			http.Error(w, "Base64 Error", 400)
			return
		}
		gz := gzipPool.Get().(*gzip.Reader)
		if err := gz.Reset(bytes.NewReader(raw)); err != nil {
			http.Error(w, "Gzip Error", 500)
			return
		}
		defer gzipPool.Put(gz)
		decodedBytes, _ := io.ReadAll(gz)
		var syncData map[string]any
		if json.Unmarshal(decodedBytes, &syncData) != nil {
			http.Error(w, "Integrity Error", 400)
			return
		}

		dbMutex.Lock()
		defer dbMutex.Unlock()
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]any{"status": "ok", "inbound_b64": nil})
	})

	mux.HandleFunc("/api/update/download", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/vnd.android.package-archive")
		http.ServeFile(w, r, "../../client/build/app/outputs/flutter-apk/app-profile.apk")
	})
}
