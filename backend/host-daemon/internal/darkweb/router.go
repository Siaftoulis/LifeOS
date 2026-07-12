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
	
	rows, err := DB.Query("SELECT info_hash, name, status, progress FROM torrents")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var torrents []map[string]interface{}
	for rows.Next() {
		var hash, name, status string
		var progress float64
		if err := rows.Scan(&hash, &name, &status, &progress); err == nil {
			torrents = append(torrents, map[string]interface{}{
				"info_hash": hash,
				"name":      name,
				"status":    status,
				"progress":  progress,
			})
		}
	}
	json.NewEncoder(w).Encode(torrents)
}

func HandleAddTorrent(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var req map[string]string
	if err := json.NewDecoder(r.Body).Decode(&req); err == nil {
		hash := req["info_hash"]
		name := req["name"]
		if hash != "" && name != "" {
			DB.Exec("INSERT INTO torrents (info_hash, name, status, progress) VALUES (?, ?, 'DOWNLOADING', 0.0)", hash, name)
		}
	}
	json.NewEncoder(w).Encode(map[string]interface{}{"status": "added"})
}

func HandleDeleteTorrent(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var req map[string]string
	if err := json.NewDecoder(r.Body).Decode(&req); err == nil {
		hash := req["info_hash"]
		if hash != "" {
			DB.Exec("DELETE FROM torrents WHERE info_hash = ?", hash)
		}
	}
	json.NewEncoder(w).Encode(map[string]interface{}{"status": "deleted"})
}

func HandlePromoteFile(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{"status": "promoted"})
}
