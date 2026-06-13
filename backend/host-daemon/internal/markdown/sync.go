package markdown

import (
	"encoding/json"
	"net/http"
	"os"
	"path/filepath"
)

type SyncPayload struct {
	FilePath string `json:"file_path"`
	Content  string `json:"content"`
}

func HandleSync(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var p SyncPayload
	if err := json.NewDecoder(r.Body).Decode(&p); err != nil || p.FilePath == "" {
		http.Error(w, "Bad request", http.StatusBadRequest)
		return
	}

	basePath := "./vault" // Usually derived from config
	fullPath := filepath.Join(basePath, p.FilePath)

	if err := os.MkdirAll(filepath.Dir(fullPath), 0755); err != nil {
		http.Error(w, "Internal error", http.StatusInternalServerError)
		return
	}

	if err := os.WriteFile(fullPath, []byte(p.Content), 0644); err != nil {
		http.Error(w, "Internal error", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status": "ok"}`))
}
