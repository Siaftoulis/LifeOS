package location

import (
	"encoding/json"
	"log"
	"net/http"
	"sync"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

type LiveUpdate struct {
	Type      string  `json:"type"`
	DeviceID  string  `json:"device_id"`
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Velocity  float64 `json:"velocity,omitempty"`
	Altitude  float64 `json:"altitude,omitempty"`
	Timestamp int64   `json:"timestamp"`
}

type Broker struct {
	mu      sync.RWMutex
	clients map[*websocket.Conn]string
}

var DefaultBroker = &Broker{
	clients: make(map[*websocket.Conn]string),
}

func (b *Broker) Register(conn *websocket.Conn, deviceID string) {
	b.mu.Lock()
	defer b.mu.Unlock()
	b.clients[conn] = deviceID
	log.Printf("WebSocket client registered: %s (total: %d)", deviceID, len(b.clients))
}

func (b *Broker) Unregister(conn *websocket.Conn) {
	b.mu.Lock()
	defer b.mu.Unlock()
	deviceID := b.clients[conn]
	delete(b.clients, conn)
	conn.Close()
	log.Printf("WebSocket client disconnected: %s (total: %d)", deviceID, len(b.clients))
}

func (b *Broker) Broadcast(update LiveUpdate) {
	b.mu.RLock()
	defer b.mu.RUnlock()
	data, err := json.Marshal(update)
	if err != nil {
		log.Printf("Broadcast marshal error: %v", err)
		return
	}
	for conn := range b.clients {
		if err := conn.WriteMessage(websocket.TextMessage, data); err != nil {
			log.Printf("Broadcast write error: %v", err)
			go b.Unregister(conn)
		}
	}
}

func HandleLiveRadar(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("WebSocket upgrade failed: %v", err)
		return
	}

	deviceID := r.URL.Query().Get("device_id")
	if deviceID == "" {
		deviceID = "anon"
	}

	DefaultBroker.Register(conn, deviceID)
	defer DefaultBroker.Unregister(conn)

	for {
		_, msg, err := conn.ReadMessage()
		if err != nil {
			break
		}

		var update LiveUpdate
		if err := json.Unmarshal(msg, &update); err != nil {
			log.Printf("WebSocket unmarshal error: %v", err)
			continue
		}

		update.DeviceID = deviceID
		DefaultBroker.Broadcast(update)
	}
}
