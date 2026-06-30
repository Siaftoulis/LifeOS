package gallery

import (
	"encoding/json"
	"log"
	"net/http"
	"path/filepath"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/gallery/upload", handleUpload)
	mux.HandleFunc("/api/v1/gallery/assets", handleAssets)
	mux.HandleFunc("/api/v1/gallery/thumbnail", handleThumbnail)
	mux.HandleFunc("/api/v1/gallery/stream", handleStream)
}

func handleUpload(w http.ResponseWriter, r *http.Request) {
	err := r.ParseMultipartForm(100 << 20) // 100 MB max
	if err != nil {
		http.Error(w, "Failed to parse form", http.StatusBadRequest)
		return
	}

	userID := r.FormValue("user_id")
	deviceID := r.FormValue("device_id")
	assetID := r.FormValue("asset_id")
	assetType := r.FormValue("type") // PHOTO or VIDEO
	createdAt := r.FormValue("created_at")

	if userID == "" || assetID == "" {
		http.Error(w, "Missing user_id or asset_id", http.StatusBadRequest)
		return
	}

	file, header, err := r.FormFile("file")
	if err != nil {
		http.Error(w, "Missing file", http.StatusBadRequest)
		return
	}
	defer file.Close()

	// Save file to disk
	relPath, err := SaveAsset("./data", userID, deviceID, header.Filename, file)
	if err != nil {
		http.Error(w, "Failed to save file", http.StatusInternalServerError)
		return
	}

	// Insert into SQLite
	if DB != nil {
		query := `INSERT INTO assets (id, user_id, device_id, filename, type, created_at, size_bytes, filepath) 
		          VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
		_, err = DB.Exec(query, assetID, userID, deviceID, header.Filename, assetType, createdAt, header.Size, relPath)
		if err != nil {
			// Log error but we still saved the file
			log.Printf("Failed to insert asset into db: %v", err)
		}
	}

	w.WriteHeader(http.StatusCreated)
	w.Write([]byte(`{"status": "success", "id": "` + assetID + `"}`))
}

func handleAssets(w http.ResponseWriter, r *http.Request) {
	if DB == nil {
		http.Error(w, "Database not initialized", http.StatusInternalServerError)
		return
	}

	rows, err := DB.Query(`SELECT id, user_id, device_id, filename, type, created_at, size_bytes FROM assets ORDER BY created_at DESC`)
	if err != nil {
		http.Error(w, "Database query error", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var results []map[string]interface{}
	for rows.Next() {
		var id, userID, deviceID, filename, assetType, createdAt string
		var sizeBytes int
		if err := rows.Scan(&id, &userID, &deviceID, &filename, &assetType, &createdAt, &sizeBytes); err != nil {
			continue
		}
		results = append(results, map[string]interface{}{
			"id":         id,
			"user_id":    userID,
			"device_id":  deviceID,
			"filename":   filename,
			"type":       assetType,
			"created_at": createdAt,
			"size_bytes": sizeBytes,
		})
	}

	if results == nil {
		results = []map[string]interface{}{}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(results)
}

func handleThumbnail(w http.ResponseWriter, r *http.Request) {
	// For now just return empty, since client can try to load original file stream or cache
	w.WriteHeader(http.StatusNotImplemented)
}

func handleStream(w http.ResponseWriter, r *http.Request) {
	// Implement file serving
	id := r.URL.Query().Get("id")
	if DB == nil || id == "" {
		http.Error(w, "Missing ID", http.StatusBadRequest)
		return
	}

	var relPath string
	err := DB.QueryRow("SELECT filepath FROM assets WHERE id = ?", id).Scan(&relPath)
	if err != nil {
		http.Error(w, "Not found", http.StatusNotFound)
		return
	}

	absPath := filepath.Join("./data", relPath)
	http.ServeFile(w, r, absPath)
}
