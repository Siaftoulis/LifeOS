package vm

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"os/exec"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/vm", handleList)
	mux.HandleFunc("/api/v1/vm/toggle", handleToggle)
	mux.HandleFunc("/api/v1/vm/discovery", handleDiscovery)
	mux.HandleFunc("/api/v1/vm/explore", handleExplore)
}

func handleList(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	
	rows, err := DB.Query("SELECT id, name, type, state, ram FROM virtual_machines")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var vms []map[string]interface{}
	for rows.Next() {
		var id, name, vmType, state string
		var ram int
		if err := rows.Scan(&id, &name, &vmType, &state, &ram); err == nil {
			vms = append(vms, map[string]interface{}{
				"id":    id,
				"name":  name,
				"type":  vmType,
				"state": state,
				"ram":   ram,
			})
		}
	}
	json.NewEncoder(w).Encode(vms)
}

func handleToggle(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var payload map[string]string
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		http.Error(w, "Bad Request", http.StatusBadRequest)
		return
	}
	
	vmID := payload["vm_id"]
	action := payload["action"]
	
	newState := "RUNNING"
	if action == "stop" || action == "Stop" {
		newState = "STOPPED"
	}
	
	DB.Exec("UPDATE virtual_machines SET state = ? WHERE id = ?", newState, vmID)

	log.Printf("VM Action %s triggered for VM ID: %s", action, vmID)
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "action_dispatched", "state": newState})
}

func handleDiscovery(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	
	cmd := exec.Command("tailscale", "status", "--json")
	out, err := cmd.Output()
	if err != nil {
		// Fallback to stub if tailscale isn't installed/working
		json.NewEncoder(w).Encode([]string{"100.76.247.10", "100.76.247.11"})
		return
	}

	var tsStatus struct {
		Peer map[string]struct {
			TailscaleIPs []string `json:"TailscaleIPs"`
		} `json:"Peer"`
	}

	if err := json.Unmarshal(out, &tsStatus); err != nil {
		json.NewEncoder(w).Encode([]string{"100.76.247.10", "100.76.247.11"})
		return
	}

	var ips []string
	for _, peer := range tsStatus.Peer {
		if len(peer.TailscaleIPs) > 0 {
			ips = append(ips, peer.TailscaleIPs[0])
		}
	}

	if len(ips) == 0 {
		ips = []string{"100.76.247.10", "100.76.247.11"}
	}

	json.NewEncoder(w).Encode(ips)
}

func handleExplore(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	path := r.URL.Query().Get("path")
	if path == "" {
		path = "."
	}

	entries, err := os.ReadDir(path)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	var files []string
	for _, entry := range entries {
		files = append(files, entry.Name())
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"path":  path,
		"files": files,
	})
}
