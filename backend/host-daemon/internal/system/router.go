package system

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
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
			// Stub Child Lock Interceptor
			userRole := r.Header.Get("X-User-Role")
			if userRole == "CHILD" {
				http.Error(w, "Unauthorized: Child profiles cannot modify system settings", http.StatusForbidden)
				return
			}

			var newSetting Setting
			if err := json.NewDecoder(r.Body).Decode(&newSetting); err != nil {
				http.Error(w, "Bad Request", http.StatusBadRequest)
				return
			}
			settings, err := loadSettings()
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

	mux.HandleFunc("/api/v1/system/nodes", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
			return
		}
		nodes, err := QueryTailscaleNodes()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(nodes)
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
}
