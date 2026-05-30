package markdown

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"path/filepath"
)

func RegisterRoutes(mux *http.ServeMux, storagePath string) {
	mux.HandleFunc("/api/markdown/sync", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", 405)
			return
		}
		var p struct{ Filename, Content string }
		if err := json.NewDecoder(r.Body).Decode(&p); err != nil || p.Filename == "" {
			http.Error(w, "Bad request", 400)
			return
		}
		if err := os.MkdirAll("./vault", 0755); err != nil {
			http.Error(w, "Internal error", 500)
			return
		}
		if err := os.WriteFile(filepath.Join("./vault", filepath.Base(p.Filename)), []byte(p.Content), 0644); err != nil {
			http.Error(w, "Internal error", 500)
			return
		}
	})

	mux.HandleFunc("/api/markdown/", func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				log.Printf("Panic in markdown route: %v", err)
				http.Error(w, "Internal Server Error", 500)
			}
		}()
		filename := r.URL.Path[len("/api/markdown/"):]
		if filename == "" {
			http.Error(w, "File not specified", 400)
			return
		}
		http.ServeFile(w, r, filepath.Join(storagePath, filename))
	})
}
