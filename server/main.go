package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"sync"
)

type SyncEnvelope struct {
	EventID   string          `json:"event_id"`
	Type      string          `json:"type"`
	Timestamp int64           `json:"timestamp"`
	Payload   json.RawMessage `json:"payload"`
}

var vaultMutex sync.Mutex

func saveToGenericVault(env SyncEnvelope) {
	vaultMutex.Lock()
	defer vaultMutex.Unlock()
	data, err := json.Marshal(env)
	if err != nil {
		log.Println("Error marshaling:", err)
		return
	}
	f, err := os.OpenFile("generic_vault.jsonl", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		log.Println("Error opening vault:", err)
		return
	}
	defer f.Close()
	if _, err := f.Write(append(data, '\n')); err != nil {
		log.Println("Error writing:", err)
	}
}

func handleSync(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
		return
	}
	var env SyncEnvelope
	if err := json.NewDecoder(r.Body).Decode(&env); err != nil {
		http.Error(w, "Bad Request", http.StatusBadRequest)
		return
	}
	switch env.Type {
	case "task_capture":
		fmt.Printf("Received task: %s\n", string(env.Payload))
	case "obsidian_note":
		fmt.Printf("Received note: %s\n", string(env.Payload))
	default:
		saveToGenericVault(env)
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status": "SYNC_OK"}`))
}

func main() {
	http.HandleFunc("/api/sync", handleSync)
	log.Println("Starting LifeOS Daemon on :8080...")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatal(err)
	}
}
