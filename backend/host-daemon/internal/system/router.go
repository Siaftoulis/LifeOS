package system

import (
	"encoding/json"
	"log"
	"net/http"
	"os"

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
}
