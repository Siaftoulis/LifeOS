package books

import (
	"net/http"
	"path/filepath"
)

// StreamAudiobookHandler implements Accept-Ranges byte-range serving for M4B/MP3 streams.
func StreamAudiobookHandler(w http.ResponseWriter, r *http.Request) {
	audioID := r.URL.Query().Get("id")
	if audioID == "" {
		http.Error(w, "Missing audiobook ID", http.StatusBadRequest)
		return
	}
	
	filePath := filepath.Join("storage", "audiobooks", audioID+".mp3")
	
	http.ServeFile(w, r, filePath)
}
