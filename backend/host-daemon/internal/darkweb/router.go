package darkweb

import (
	"encoding/json"
	"net/http"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/darkweb/torrents", HandleListTorrents)
	mux.HandleFunc("/api/v1/darkweb/torrents/add", HandleAddTorrent)
	mux.HandleFunc("/api/v1/darkweb/torrents/delete", HandleDeleteTorrent)
	mux.HandleFunc("/api/v1/darkweb/promote", HandlePromoteFile)
}

func HandleListTorrents(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	// Stub response for transmission-daemon query
	json.NewEncoder(w).Encode([]map[string]interface{}{
		{"info_hash": "deadbeef12345", "name": "Ubuntu 24.04 ISO", "status": "SEEDING", "progress": 1.0},
	})
}

func HandleAddTorrent(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{"status": "added"})
}

func HandleDeleteTorrent(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{"status": "deleted"})
}

func HandlePromoteFile(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{"status": "promoted"})
}
