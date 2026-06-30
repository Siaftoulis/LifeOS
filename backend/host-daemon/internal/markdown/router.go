package markdown

import (
	"log"
	"net/http"
	"path/filepath"
)

func RegisterRoutes(mux *http.ServeMux, storagePath string) {
	// Setup the filesystem watcher
	StartWatcher(storagePath)

	mux.HandleFunc("/api/markdown/sync", HandleSync)
	mux.HandleFunc("/api/markdown/collab", HandleCollab)

	mux.HandleFunc("/api/markdown/history", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"history": []}`)) // Stub
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
