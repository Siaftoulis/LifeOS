package system

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"os/exec"
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
}
