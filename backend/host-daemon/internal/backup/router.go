package backup

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"time"
)

var BackupDir = "./data/backups"

func RegisterRoutes(mux *http.ServeMux) {
	err := os.MkdirAll(BackupDir, 0755)
	if err != nil {
		log.Printf("Failed to create backup dir: %v", err)
	}

	mux.HandleFunc("/api/v1/backup/upload", handleUpload)
	mux.HandleFunc("/api/v1/backup/download", handleDownload)
}

func handleUpload(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	err := r.ParseMultipartForm(500 << 20) // 500 MB max
	if err != nil {
		http.Error(w, "Failed to parse form", http.StatusBadRequest)
		return
	}

	deviceID := r.FormValue("device_id")
	if deviceID == "" {
		deviceID = "unknown_device"
	}

	file, header, err := r.FormFile("backup_file")
	if err != nil {
		http.Error(w, "Missing backup_file", http.StatusBadRequest)
		return
	}
	defer file.Close()

	// Ensure it has .pds extension
	filename := header.Filename
	if filepath.Ext(filename) != ".pds" {
		filename = fmt.Sprintf("backup_%s_%d.pds", deviceID, time.Now().Unix())
	}

	destPath := filepath.Join(BackupDir, filename)
	destFile, err := os.Create(destPath)
	if err != nil {
		http.Error(w, "Failed to create file on server", http.StatusInternalServerError)
		return
	}
	defer destFile.Close()

	_, err = io.Copy(destFile, file)
	if err != nil {
		http.Error(w, "Failed to write file", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
	w.Write([]byte(fmt.Sprintf(`{"status": "success", "filename": "%s"}`, filename)))
}

func handleDownload(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	filename := r.URL.Query().Get("filename")
	if filename == "" {
		// Find latest backup if no filename is specified
		files, err := os.ReadDir(BackupDir)
		if err != nil || len(files) == 0 {
			http.Error(w, "No backups found", http.StatusNotFound)
			return
		}

		var latest os.FileInfo
		for _, f := range files {
			if f.IsDir() || filepath.Ext(f.Name()) != ".pds" {
				continue
			}
			info, err := f.Info()
			if err != nil {
				continue
			}
			if latest == nil || info.ModTime().After(latest.ModTime()) {
				latest = info
			}
		}

		if latest == nil {
			http.Error(w, "No backups found", http.StatusNotFound)
			return
		}
		filename = latest.Name()
	}

	absPath := filepath.Join(BackupDir, filename)
	if _, err := os.Stat(absPath); os.IsNotExist(err) {
		http.Error(w, "Backup not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=%s", filename))
	w.Header().Set("Content-Type", "application/octet-stream")
	http.ServeFile(w, r, absPath)
}
