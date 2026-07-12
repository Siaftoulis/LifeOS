package backup

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"
)

var BackupDir = "./data/backups"
var TempDir = "./data/temp_uploads"

func RegisterRoutes(mux *http.ServeMux) {
	err := os.MkdirAll(BackupDir, 0755)
	if err != nil {
		log.Printf("Failed to create backup dir: %v", err)
	}
	err = os.MkdirAll(TempDir, 0755)
	if err != nil {
		log.Printf("Failed to create temp uploads dir: %v", err)
	}

	mux.HandleFunc("/api/v1/backup/list", handleList)
	mux.HandleFunc("/api/v1/backup/upload", handleUpload)
	mux.HandleFunc("/api/v1/backup/download", handleDownload)
	mux.HandleFunc("/api/v1/backup/upload/chunk", handleChunkUpload)
	mux.HandleFunc("/api/v1/backup/upload/merge", handleMergeUpload)
}

func handleList(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	
	rows, err := DB.Query("SELECT id, device_id, name, last_backup, backup_status FROM device_backups ORDER BY last_backup DESC")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var backups []map[string]interface{}
	for rows.Next() {
		var id, deviceId, name, status string
		var lastBackup int64
		if err := rows.Scan(&id, &deviceId, &name, &lastBackup, &status); err == nil {
			backups = append(backups, map[string]interface{}{
				"id":            id,
				"device_id":     deviceId,
				"name":          name,
				"last_backup":   lastBackup,
				"backup_status": status,
			})
		}
	}
	
	importJson := "encoding/json"
	_ = importJson
	// Since json is imported at top level
	importJsonEncoder := json.NewEncoder(w)
	importJsonEncoder.Encode(backups)
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

	AddBackupRecord(filename, deviceID)

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

func handleChunkUpload(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	err := r.ParseMultipartForm(50 << 20) // 50 MB max per chunk
	if err != nil {
		http.Error(w, "Failed to parse form", http.StatusBadRequest)
		return
	}

	uploadID := r.FormValue("upload_id")
	chunkIndexStr := r.FormValue("chunk_index")

	if uploadID == "" || chunkIndexStr == "" {
		http.Error(w, "Missing upload_id or chunk_index", http.StatusBadRequest)
		return
	}

	chunkIndex, err := strconv.Atoi(chunkIndexStr)
	if err != nil || chunkIndex < 0 {
		http.Error(w, "Invalid chunk_index", http.StatusBadRequest)
		return
	}

	file, _, err := r.FormFile("chunk_file")
	if err != nil {
		http.Error(w, "Missing chunk_file", http.StatusBadRequest)
		return
	}
	defer file.Close()

	uploadDir := filepath.Join(TempDir, uploadID)
	err = os.MkdirAll(uploadDir, 0755)
	if err != nil {
		http.Error(w, "Failed to create upload temp dir", http.StatusInternalServerError)
		return
	}

	chunkPath := filepath.Join(uploadDir, strconv.Itoa(chunkIndex))
	destFile, err := os.Create(chunkPath)
	if err != nil {
		http.Error(w, "Failed to create chunk file on server", http.StatusInternalServerError)
		return
	}
	defer destFile.Close()

	_, err = io.Copy(destFile, file)
	if err != nil {
		http.Error(w, "Failed to write chunk", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status": "chunk_uploaded"}`))
}

func handleMergeUpload(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		UploadID    string `json:"upload_id"`
		Filename    string `json:"filename"`
		TotalChunks int    `json:"total_chunks"`
		Checksum    string `json:"checksum"`
		DeviceID    string `json:"device_id"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Bad Request", http.StatusBadRequest)
		return
	}

	if req.UploadID == "" || req.Filename == "" || req.TotalChunks <= 0 || req.Checksum == "" {
		http.Error(w, "Missing required fields", http.StatusBadRequest)
		return
	}

	uploadDir := filepath.Join(TempDir, req.UploadID)
	destPath := filepath.Join(BackupDir, req.Filename)
	destFile, err := os.Create(destPath)
	if err != nil {
		http.Error(w, "Failed to create merged file", http.StatusInternalServerError)
		return
	}
	defer destFile.Close()

	hasher := sha256.New()
	multiWriter := io.MultiWriter(destFile, hasher)

	for i := 0; i < req.TotalChunks; i++ {
		chunkPath := filepath.Join(uploadDir, strconv.Itoa(i))
		chunkFile, err := os.Open(chunkPath)
		if err != nil {
			destFile.Close()
			os.Remove(destPath)
			http.Error(w, fmt.Sprintf("Missing chunk %d", i), http.StatusBadRequest)
			return
		}

		_, err = io.Copy(multiWriter, chunkFile)
		chunkFile.Close()
		if err != nil {
			destFile.Close()
			os.Remove(destPath)
			http.Error(w, "Error writing merged file", http.StatusInternalServerError)
			return
		}
	}

	calculatedChecksum := hex.EncodeToString(hasher.Sum(nil))
	if calculatedChecksum != req.Checksum {
		destFile.Close()
		os.Remove(destPath)
		http.Error(w, fmt.Sprintf("Integrity mismatch: expected %s, got %s", req.Checksum, calculatedChecksum), http.StatusBadRequest)
		return
	}

	deviceID := req.DeviceID
	if deviceID == "" {
		deviceID = "unknown_device"
	}
	AddBackupRecord(req.Filename, deviceID)

	os.RemoveAll(uploadDir)

	w.WriteHeader(http.StatusOK)
	w.Write([]byte(fmt.Sprintf(`{"status": "success", "filename": "%s"}`, req.Filename)))
}
