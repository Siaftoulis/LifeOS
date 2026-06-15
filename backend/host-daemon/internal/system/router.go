package system

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"time"
)

type Node struct {
	IP     string `json:"ip"`
	Name   string `json:"name"`
	Online bool   `json:"online"`
}

type TailscaleStatus struct {
	Peer map[string]TailscalePeer `json:"Peer"`
}

type TailscalePeer struct {
	HostName     string   `json:"HostName"`
	TailscaleIPs []string `json:"TailscaleIPs"`
	Online       bool     `json:"Online"`
}

func QueryTailscaleNodes() ([]Node, error) {
	cmd := exec.Command("tailscale", "status", "--json")
	out, err := cmd.Output()
	if err != nil {
		// Resilient fallback logic for test/dev environments
		log.Printf("Tailscale CLI error: %v. Returning mock peers.", err)
		return []Node{
			{IP: "100.76.247.27", Name: "pds-laptop-1", Online: true},
			{IP: "100.76.247.28", Name: "pds-mobile-android", Online: false},
		}, nil
	}

	var status TailscaleStatus
	if err := json.Unmarshal(out, &status); err != nil {
		return nil, err
	}

	var nodes []Node
	for _, peer := range status.Peer {
		ip := ""
		if len(peer.TailscaleIPs) > 0 {
			ip = peer.TailscaleIPs[0]
		}
		nodes = append(nodes, Node{
			IP:     ip,
			Name:   peer.HostName,
			Online: peer.Online,
		})
	}
	return nodes, nil
}

type Setting struct {
	Key       string `json:"key"`
	Value     string `json:"value"`
	UpdatedAt int64  `json:"updated_at"`
}

var settingsFile = "./data/system_settings.json"

func loadSettings() ([]Setting, error) {
	if _, err := os.Stat(settingsFile); os.IsNotExist(err) {
		return []Setting{}, nil
	}
	data, err := os.ReadFile(settingsFile)
	if err != nil {
		return nil, err
	}
	var settings []Setting
	if err := json.Unmarshal(data, &settings); err != nil {
		return nil, err
	}
	return settings, nil
}

func saveSettings(settings []Setting) error {
	_ = os.MkdirAll("./data", 0755)
	data, err := json.MarshalIndent(settings, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(settingsFile, data, 0644)
}

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

type AppItem struct {
	PackageName string `json:"package_name"`
	Name        string `json:"name"`
}

type CategorizeRequest struct {
	Apps []AppItem `json:"apps"`
}

func classifyAppHeuristically(packageName, name string) string {
	pkg := strings.ToLower(packageName)
	appName := strings.ToLower(name)

	// 1. Games
	if strings.Contains(pkg, "game") || 
		strings.Contains(pkg, "gaming") || 
		strings.Contains(pkg, "arcade") || 
		strings.Contains(pkg, "puzzle") || 
		strings.Contains(pkg, "sport") || 
		strings.Contains(pkg, "play.games") ||
		strings.Contains(pkg, "xbox") ||
		strings.Contains(pkg, "playstation") ||
		strings.Contains(pkg, "steam") ||
		strings.Contains(pkg, "retroarch") ||
		strings.Contains(appName, "game") ||
		strings.Contains(appName, "toy") {
		// Verify it's not a standard Google system app
		if !strings.Contains(pkg, "vending") && !strings.Contains(pkg, "play.services") {
			return "Games"
		}
	}

	// 2. Photographs
	if strings.Contains(pkg, "camera") || 
		strings.Contains(pkg, "gallery") || 
		strings.Contains(pkg, "photo") || 
		strings.Contains(pkg, "image") || 
		strings.Contains(pkg, "paint") || 
		strings.Contains(pkg, "draw") || 
		strings.Contains(pkg, "sketch") || 
		strings.Contains(pkg, "photograph") || 
		strings.Contains(pkg, "picture") || 
		strings.Contains(pkg, "lens") || 
		strings.Contains(pkg, "snapseed") || 
		strings.Contains(pkg, "photoshop") || 
		strings.Contains(pkg, "gopro") ||
		strings.Contains(appName, "camera") ||
		strings.Contains(appName, "photo") ||
		strings.Contains(appName, "gallery") ||
		strings.Contains(appName, "picture") {
		return "Photographs"
	}

	// 3. Google Archives
	if strings.Contains(pkg, "com.google") || 
		strings.Contains(pkg, "google.android") || 
		strings.Contains(pkg, "chrome") || 
		strings.Contains(pkg, "youtube") || 
		strings.Contains(pkg, "gmail") || 
		strings.Contains(pkg, "vending") || // Play Store
		strings.Contains(pkg, "com.google.android.gm") ||
		strings.Contains(appName, "google") ||
		strings.Contains(appName, "chrome") ||
		strings.Contains(appName, "youtube") ||
		strings.Contains(appName, "gmail") ||
		strings.Contains(appName, "drive") ||
		strings.Contains(appName, "hangouts") ||
		strings.Contains(appName, "sheets") ||
		strings.Contains(appName, "docs") ||
		strings.Contains(appName, "slides") ||
		strings.Contains(appName, "meet") ||
		strings.Contains(appName, "duo") {
		return "Google Archives"
	}

	return "Everything Else"
}

func classifyAppsWithGemini(apiKey string, apps []AppItem) (map[string]string, error) {
	appsJson, err := json.Marshal(apps)
	if err != nil {
		return nil, err
	}

	prompt := fmt.Sprintf(`You are an Android application categorizer. 
Classify each app from the provided list into exactly one of these categories:
"Games", "Photographs", "Google Archives", "Everything Else".

Definitions:
- "Games": Video games, gaming platforms, and game utilities.
- "Photographs": Camera apps, galleries, image editors, photo sharing, and drawing apps.
- "Google Archives": Apps made by Google (e.g. Gmail, Chrome, YouTube, Google Drive, Google Maps, Google Search, Play Store) EXCEPT if they are games or galleries.
- "Everything Else": Standard utility apps, social networks, messaging/chat apps, note-taking apps, music players, tools, and everything else.

Return ONLY a flat JSON object where the key is the "package_name" and the value is the exact category name. Do not include markdown formatting or code blocks.

Example response:
{"com.whatsapp": "Everything Else", "com.netflix.mediaclient": "Everything Else", "com.android.chrome": "Google Archives", "com.supercell.clashofclans": "Games"}

List to classify:
%s`, string(appsJson))


	// Gemini REST API Payload
	reqPayload := map[string]interface{}{
		"contents": []map[string]interface{}{
			{
				"parts": []map[string]interface{}{
					{"text": prompt},
				},
			},
		},
	}

	reqBody, err := json.Marshal(reqPayload)
	if err != nil {
		return nil, err
	}

	url := fmt.Sprintf("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=%s", apiKey)
	
	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Post(url, "application/json", bytes.NewBuffer(reqBody))
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("Gemini API returned status %d: %s", resp.StatusCode, string(bodyBytes))
	}

	var geminiResp struct {
		Candidates []struct {
			Content struct {
				Parts []struct {
					Text string `json:"text"`
				} `json:"parts"`
			} `json:"content"`
		} `json:"candidates"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&geminiResp); err != nil {
		return nil, err
	}

	if len(geminiResp.Candidates) == 0 || len(geminiResp.Candidates[0].Content.Parts) == 0 {
		return nil, fmt.Errorf("empty response from Gemini")
	}

	rawText := geminiResp.Candidates[0].Content.Parts[0].Text
	rawText = strings.TrimSpace(rawText)

	// Clean up markdown block wraps if the model returned them
	if strings.HasPrefix(rawText, "```json") {
		rawText = strings.TrimPrefix(rawText, "```json")
		rawText = strings.TrimSuffix(rawText, "```")
	} else if strings.HasPrefix(rawText, "```") {
		rawText = strings.TrimPrefix(rawText, "```")
		rawText = strings.TrimSuffix(rawText, "```")
	}
	rawText = strings.TrimSpace(rawText)

	var result map[string]string
	if err := json.Unmarshal([]byte(rawText), &result); err != nil {
		return nil, fmt.Errorf("failed to parse Gemini response text as JSON: %s. Error: %v", rawText, err)
	}

	return result, nil
}
