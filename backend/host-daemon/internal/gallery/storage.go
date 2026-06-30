package gallery

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"
)

// SaveAsset receives an uploaded file and saves it to the appropriate directory structure
// e.g. data/gallery/user_id/year/month/filename
func SaveAsset(dataDir, userID, deviceID, filename string, r io.Reader) (string, error) {
	now := time.Now()
	yearStr := fmt.Sprintf("%04d", now.Year())
	monthStr := fmt.Sprintf("%02d", now.Month())

	relDir := filepath.Join("gallery", userID, yearStr, monthStr)
	absDir := filepath.Join(dataDir, relDir)

	if err := os.MkdirAll(absDir, 0755); err != nil {
		return "", fmt.Errorf("failed to create directory: %v", err)
	}

	// append deviceId to filename if needed, or keep original
	absPath := filepath.Join(absDir, filename)

	out, err := os.Create(absPath)
	if err != nil {
		return "", fmt.Errorf("failed to create file: %v", err)
	}
	defer out.Close()

	if _, err := io.Copy(out, r); err != nil {
		return "", fmt.Errorf("failed to save file content: %v", err)
	}

	return filepath.Join(relDir, filename), nil
}
