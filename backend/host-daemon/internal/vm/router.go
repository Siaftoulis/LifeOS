package vm

import (
	"encoding/json"
	"log"
	"net/http"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/vm", handleList)
	mux.HandleFunc("/api/v1/vm/toggle", handleToggle)
	mux.HandleFunc("/api/v1/vm/discovery", handleDiscovery)
	mux.HandleFunc("/api/v1/vm/explore", handleExplore)
}

func handleList(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	// Stub Docker/Firecracker list
	json.NewEncoder(w).Encode([]map[string]interface{}{
		{"id": "vm_1", "name": "Dev-Sandbox", "type": "MICROVM", "state": "RUNNING", "ram": 2048},
		{"id": "vm_2", "name": "Database-Local", "type": "CONTAINER", "state": "RUNNING", "ram": 1024},
		{"id": "vm_3", "name": "Windows-Game", "type": "DESKTOP", "state": "STOPPED", "ram": 8192},
	})
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
	// Stub execution
	log.Printf("VM Action %s triggered for VM ID: %s", payload["action"], payload["vm_id"])
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "action_dispatched"})
}

func handleDiscovery(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	// Stub Tailscale node discovery
	json.NewEncoder(w).Encode([]string{"100.76.247.10", "100.76.247.11"})
}

func handleExplore(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	// Stub File Explorer
	json.NewEncoder(w).Encode(map[string]interface{}{
		"path": r.URL.Query().Get("path"),
		"files": []string{"src", "docs", "main.py", "requirements.txt"},
	})
}
