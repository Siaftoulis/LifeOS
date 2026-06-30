package media

import (
	"log"
	"net/http"
	"path/filepath"
	"strings"
)

func RegisterRoutes(mux *http.ServeMux, allowedDir string) {
	mux.HandleFunc("/api/media/", func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				log.Printf("Panic in media route: %v", err)
				http.Error(w, "Internal Server Error", 500)
			}
		}()

		target := r.URL.Query().Get("file")
		if target == "" {
			target = r.URL.Path[len("/api/media/"):]
		}

		if target == "" || strings.Contains(target, "..") {
			http.Error(w, "Invalid or unauthorized path", http.StatusBadRequest)
			return
		}

		fullPath := filepath.Join(allowedDir, target)
		http.ServeFile(w, r, fullPath)
	})
}
