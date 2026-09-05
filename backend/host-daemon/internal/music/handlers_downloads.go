package music

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
	"time"
)

func HandleGetDownloadQueue(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	status := r.URL.Query().Get("status")
	query := "SELECT id, track_id, url, destination_path, status, priority, retry_count, total_bytes, downloaded_bytes, error_message, wifi_only, charging_only, created_at, started_at, completed_at FROM download_queue"
	var args []any
	if status != "" {
		query += " WHERE status = ?"
		args = append(args, status)
	}
	query += " ORDER BY priority DESC, created_at ASC"

	rows, err := DB.Query(query, args...)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var items []DownloadQueueItem
	for rows.Next() {
		var item DownloadQueueItem
		var destPath, errMsg sql.NullString
		var totalBytes sql.NullInt64
		var startedAt, completedAt sql.NullInt64
		var wifiOnly, chargingOnly int
		if err := rows.Scan(&item.ID, &item.TrackID, &item.URL, &destPath, &item.Status, &item.Priority, &item.RetryCount,
			&totalBytes, &item.DownloadedBytes, &errMsg, &wifiOnly, &chargingOnly, &item.CreatedAt, &startedAt, &completedAt); err == nil {
			item.DestinationPath = destPath.String
			item.ErrorMessage = errMsg.String
			if totalBytes.Valid {
				item.TotalBytes = totalBytes.Int64
			}
			item.WiFiOnly = wifiOnly == 1
			item.ChargingOnly = chargingOnly == 1
			if startedAt.Valid {
				item.StartedAt = startedAt.Int64
			}
			if completedAt.Valid {
				item.CompletedAt = completedAt.Int64
			}
			items = append(items, item)
		}
	}
	if items == nil {
		items = []DownloadQueueItem{}
	}
	json.NewEncoder(w).Encode(items)
}

func HandleEnqueueDownload(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	var req struct {
		TrackID      string `json:"track_id"`
		URL          string `json:"url"`
		Priority     int    `json:"priority"`
		WiFiOnly     bool   `json:"wifi_only"`
		ChargingOnly bool   `json:"charging_only"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.TrackID == "" || req.URL == "" {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	id := "dl-" + strconv.FormatInt(time.Now().UnixNano(), 36)
	now := time.Now().UnixMilli()
	wifi := 1
	if !req.WiFiOnly {
		wifi = 0
	}
	charging := 0
	if req.ChargingOnly {
		charging = 1
	}
	_, err := DB.Exec(`INSERT INTO download_queue (id, track_id, url, status, priority, wifi_only, charging_only, created_at)
		VALUES (?, ?, ?, 'pending', ?, ?, ?, ?)`,
		id, req.TrackID, req.URL, req.Priority, wifi, charging, now)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	notifyQueue()
	json.NewEncoder(w).Encode(map[string]any{"id": id, "status": "queued"})
}

func HandleUpdateDownload(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	id := r.PathValue("id")
	var req struct {
		Status          string `json:"status"`
		DownloadedBytes int64  `json:"downloaded_bytes"`
		TotalBytes      int64  `json:"total_bytes"`
		ErrorMessage    string `json:"error_message"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request", http.StatusBadRequest)
		return
	}

	updates := []string{"status = ?"}
	args := []any{req.Status}
	if req.DownloadedBytes > 0 {
		updates = append(updates, "downloaded_bytes = ?")
		args = append(args, req.DownloadedBytes)
	}
	if req.TotalBytes > 0 {
		updates = append(updates, "total_bytes = ?")
		args = append(args, req.TotalBytes)
	}
	if req.ErrorMessage != "" {
		updates = append(updates, "error_message = ?")
		args = append(args, req.ErrorMessage)
	}
	if req.Status == "downloading" {
		updates = append(updates, "started_at = COALESCE(started_at, ?)")
		args = append(args, time.Now().UnixMilli())
	}
	if req.Status == "completed" || req.Status == "failed" {
		updates = append(updates, "completed_at = ?")
		args = append(args, time.Now().UnixMilli())
	}

	query := "UPDATE download_queue SET " + strings.Join(updates, ", ") + " WHERE id = ?"
	args = append(args, id)
	_, err := DB.Exec(query, args...)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	json.NewEncoder(w).Encode(map[string]any{"status": "updated", "id": id})
}

func HandleCancelDownload(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	id := r.PathValue("id")
	if id == "" {
		http.Error(w, "Missing id", http.StatusBadRequest)
		return
	}

	if err := CancelDownload(id); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	json.NewEncoder(w).Encode(map[string]any{"status": "cancelled", "id": id})
}

func HandleClearCompletedDownloads(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	_, err := DB.Exec("DELETE FROM download_queue WHERE status IN ('completed', 'failed', 'cancelled')")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	json.NewEncoder(w).Encode(map[string]any{"status": "cleared"})
}
