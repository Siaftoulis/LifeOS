package cloud

import (
	"net/http"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/cloud/backups", HandleGetBackups)
	mux.HandleFunc("/api/v1/cloud/web-os", HandleWebOS)
}

func HandleGetBackups(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`[]`))
}

func HandleWebOS(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Clear-Site-Data", `"cache", "cookies", "storage"`)
	w.Header().Set("Content-Type", "text/html")
	w.Write([]byte(`<!DOCTYPE html><html><body><h1>LifeOS WebOS</h1></body></html>`))
}
