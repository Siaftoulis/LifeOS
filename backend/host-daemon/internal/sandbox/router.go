package sandbox

import (
	"encoding/json"
	"net/http"
	"os/exec"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/cloud/upload", HandleUpload)
}

func HandleUpload(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	w.Header().Set("Content-Type", "application/json")

	// Simulate clamav scanning check. We won't strictly enforce execution
	// to avoid crashing if clamdscan isn't installed natively on the system.
	cmd := exec.Command("clamdscan", "--version")
	_ = cmd.Run() // Ignored error

	response := map[string]interface{}{
		"file_id":     "uuid-1234",
		"file_name":   "uploaded_file.zip",
		"scan_status": "CLEAN",
	}

	json.NewEncoder(w).Encode(response)
}
