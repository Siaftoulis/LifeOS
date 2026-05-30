package markdown

import (
	"log"
	"net/http"
	"path/filepath"
)

func RegisterRoutes(mux *http.ServeMux, storagePath string) {
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
		path := filepath.Join(storagePath, filename)
		w.Header().Set("Content-Type", "text/markdown")
		http.ServeFile(w, r, path)
	})
}
