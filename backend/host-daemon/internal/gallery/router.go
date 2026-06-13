package gallery

import (
	"encoding/json"
	"net/http"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/gallery/upload", handleUpload)
	mux.HandleFunc("/api/v1/gallery/assets", handleAssets)
	mux.HandleFunc("/api/v1/gallery/thumbnail", handleThumbnail)
	mux.HandleFunc("/api/v1/gallery/stream", handleStream)
}

func handleUpload(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusCreated)
	w.Write([]byte(`{"id": "new_asset_1", "status": "processing"}`))
}

func handleAssets(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode([]map[string]interface{}{
		{"id": "a1", "filename": "IMG_9001.jpg", "type": "PHOTO"},
		{"id": "a2", "filename": "VID_9002.mp4", "type": "VIDEO"},
	})
}

func handleThumbnail(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "image/webp")
	w.Write([]byte("Stub WebP thumbnail bytes..."))
}

func handleStream(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "video/mp4")
	w.Header().Set("Accept-Ranges", "bytes")
	w.Write([]byte("Stub video stream bytes..."))
}
