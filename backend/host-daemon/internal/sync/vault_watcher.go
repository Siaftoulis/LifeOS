package sync

import (
	"log"
	"net/http"

	"github.com/fsnotify/fsnotify"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

var vaultWatcher *fsnotify.Watcher
var vaultClients = make(map[*websocket.Conn]bool)

func InitVaultWatcher(vaultPath string) {
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		log.Printf("Failed to init Vault Watcher: %v", err)
		return
	}
	vaultWatcher = watcher

	go func() {
		for {
			select {
			case event, ok := <-watcher.Events:
				if !ok {
					return
				}
				log.Printf("Vault Event: %v", event)
				broadcastVaultEvent(event.Name, event.Op.String())
			case err, ok := <-watcher.Errors:
				if !ok {
					return
				}
				log.Printf("Vault Watcher Error: %v", err)
			}
		}
	}()

	err = watcher.Add(vaultPath)
	if err != nil {
		log.Printf("Failed to watch vault path: %v", err)
	} else {
		log.Printf("Vault Watcher started on %s", vaultPath)
	}
}

func broadcastVaultEvent(filePath, operation string) {
	msg := map[string]string{
		"file": filePath,
		"op":   operation,
	}
	for client := range vaultClients {
		if err := client.WriteJSON(msg); err != nil {
			client.Close()
			delete(vaultClients, client)
		}
	}
}

func HandleVaultSyncStream(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Upgrade failed:", err)
		return
	}
	vaultClients[conn] = true
	log.Println("Client connected to Vault Sync Stream")
	
	// Keep connection alive
	for {
		if _, _, err := conn.ReadMessage(); err != nil {
			delete(vaultClients, conn)
			break
		}
	}
}
