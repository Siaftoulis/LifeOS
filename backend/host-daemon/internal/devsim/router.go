package devsim

import (
	"encoding/json"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"fmt"
	"time"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/devsim/report", HandleReport)
}

func HandleReport(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	err := r.ParseMultipartForm(100 << 20) // 100 MB max memory
	if err != nil {
		http.Error(w, "Unable to parse form", http.StatusBadRequest)
		return
	}

	baseDir := "../../vault/03 - work/dev_simulations"
	timestamp := time.Now().Format("2006-01-02_15-04-05")
	simDir := filepath.Join(baseDir, fmt.Sprintf("sim_%s", timestamp))

	if err := os.MkdirAll(simDir, 0755); err != nil {
		http.Error(w, "Unable to create directory", http.StatusInternalServerError)
		return
	}

	// Save trace logs if exists
	logFiles := r.MultipartForm.File["trace_logs"]
	if len(logFiles) > 0 {
		file, err := logFiles[0].Open()
		if err == nil {
			defer file.Close()
			out, err := os.Create(filepath.Join(simDir, "trace_logs.txt"))
			if err == nil {
				defer out.Close()
				io.Copy(out, file)
			}
		}
	}

	// Save screenshots
	screenshotFiles := r.MultipartForm.File["screenshots"]
	for _, fileHeader := range screenshotFiles {
		file, err := fileHeader.Open()
		if err != nil {
			continue
		}
		
		out, err := os.Create(filepath.Join(simDir, fileHeader.Filename))
		if err == nil {
			io.Copy(out, file)
			out.Close()
		}
		file.Close()
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "success",
		"path":   simDir,
	})
}
