package system

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"lifeos/host-daemon/internal/auth/middleware"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/system/settings", func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodGet {
			settings, err := loadSettings()
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(settings)
			return
		}

		if r.Method == http.MethodPost {
			settings, err := loadSettings()
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}

			childLockEnabled := false
			for _, s := range settings {
				if s.Key == "child_lock_enabled" && s.Value == "true" {
					childLockEnabled = true
					break
				}
			}

			// Real Child Lock Interceptor: role comes from the verified JWT,
			// never from a client-settable header.
			userRole, _ := r.Context().Value(middleware.RoleContextKey).(string)
			if childLockEnabled && userRole == "CHILD" {
				http.Error(w, "Unauthorized: System is locked via Child Lock", http.StatusForbidden)
				return
			}

			var newSetting Setting
			if err := json.NewDecoder(r.Body).Decode(&newSetting); err != nil {
				http.Error(w, "Bad Request", http.StatusBadRequest)
				return
			}
			settings, err = loadSettings()
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}

			found := false
			for i, s := range settings {
				if s.Key == newSetting.Key {
					settings[i].Value = newSetting.Value
					settings[i].UpdatedAt = newSetting.UpdatedAt
					found = true
					break
				}
			}
			if !found {
				settings = append(settings, newSetting)
			}

			if err := saveSettings(settings); err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}

			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(map[string]string{"status": "success"})
			return
		}

		http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
	})


	mux.HandleFunc("/api/v1/system/apps/categorize", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
			return
		}

		var req CategorizeRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "Bad Request", http.StatusBadRequest)
			return
		}

		categories := make(map[string]string)
		geminiKey := os.Getenv("GEMINI_API_KEY")

		if geminiKey != "" && len(req.Apps) > 0 {
			classified, err := classifyAppsWithGemini(geminiKey, req.Apps)
			if err == nil {
				categories = classified
			} else {
				log.Printf("Gemini classification failed: %v. Falling back to heuristics.", err)
				for _, app := range req.Apps {
					categories[app.PackageName] = classifyAppHeuristically(app.PackageName, app.Name)
				}
			}
		} else {
			for _, app := range req.Apps {
				categories[app.PackageName] = classifyAppHeuristically(app.PackageName, app.Name)
			}
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{
			"categories": categories,
		})
	})

	mux.HandleFunc("/api/v1/system/presets", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		if r.Method == http.MethodGet {
			presets, err := GetAllPresets()
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			json.NewEncoder(w).Encode(map[string]interface{}{
				"presets": presets,
			})
			return
		}

		if r.Method == http.MethodPost {
			var payload struct {
				Name    string                 `json:"name"`
				Data    map[string]interface{} `json:"data"`
				Presets map[string]interface{} `json:"presets"`
			}

			if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
				http.Error(w, "Invalid JSON payload", http.StatusBadRequest)
				return
			}

			// Batch presets backup
			if len(payload.Presets) > 0 {
				for name, pData := range payload.Presets {
					if mapData, ok := pData.(map[string]interface{}); ok {
						_ = SavePreset(name, mapData)
					}
				}
				json.NewEncoder(w).Encode(map[string]string{"status": "success", "message": "Presets synced to cloud"})
				return
			}

			// Single preset save
			if payload.Name == "" || payload.Data == nil {
				http.Error(w, "Missing name or data", http.StatusBadRequest)
				return
			}

			if err := SavePreset(payload.Name, payload.Data); err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}

			json.NewEncoder(w).Encode(map[string]string{"status": "success", "message": "Preset saved"})
			return
		}

		if r.Method == http.MethodDelete {
			name := r.URL.Query().Get("name")
			if name == "" {
				http.Error(w, "Missing name query parameter", http.StatusBadRequest)
				return
			}

			if err := DeletePreset(name); err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}

			json.NewEncoder(w).Encode(map[string]string{"status": "success", "message": "Preset deleted"})
			return
		}

		http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
	})

	mux.HandleFunc("/api/v1/system/updates/latest", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Access-Control-Allow-Origin", "*")

		if r.Method == http.MethodOptions {
			w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			w.WriteHeader(http.StatusOK)
			return
		}

		if r.Method != http.MethodGet {
			http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
			return
		}

		force := r.URL.Query().Get("refresh") == "true"
		rel, err := GetLatestRelease(force)
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to fetch release: %v", err), http.StatusInternalServerError)
			return
		}

		json.NewEncoder(w).Encode(rel)
	})

	mux.HandleFunc("/api/v1/system/updates/download", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")

		if r.Method == http.MethodOptions {
			w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			w.WriteHeader(http.StatusOK)
			return
		}

		if r.Method != http.MethodGet {
			http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
			return
		}

		assetType := strings.ToLower(r.URL.Query().Get("asset"))
		if assetType == "" {
			assetType = "apk"
		}

		rel, err := GetLatestRelease(false)
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to get release info: %v", err), http.StatusInternalServerError)
			return
		}

		cachedPath, err := DownloadAndCacheAsset(rel, assetType)
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to download asset: %v", err), http.StatusInternalServerError)
			return
		}

		filename := filepath.Base(cachedPath)
		w.Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=\"%s\"", filename))
		if strings.HasSuffix(filename, ".apk") {
			w.Header().Set("Content-Type", "application/vnd.android.package-archive")
		} else {
			w.Header().Set("Content-Type", "application/zip")
		}

		http.ServeFile(w, r, cachedPath)
	})
}

