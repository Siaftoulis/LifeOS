// Package events relays bus events to connected clients over WebSocket —
// the push side of the ecosystem: the daemon tells devices what happened,
// no polling. Clients must authenticate (?token= or Authorization header).
package events

import (
	"encoding/json"
	"log"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gorilla/websocket"

	"lifeos/host-daemon/internal/auth/middleware"
	"lifeos/host-daemon/internal/bus"
)

// CheckOrigin: any origin is fine — every connection requires a valid token.
var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
	// ponytail: allows non-tailnet origins (web portal via Funnel); token
	// auth is the security boundary here, not the origin check.
}

type client struct {
	conn *websocket.Conn
	mu   sync.Mutex // WriteMessage is not concurrency-safe; bus workers publish concurrently
}

type Broker struct {
	mu      sync.RWMutex
	clients map[*client]struct{}
}

var DefaultBroker = &Broker{clients: make(map[*client]struct{})}

func (b *Broker) register(c *client) {
	b.mu.Lock()
	b.clients[c] = struct{}{}
	b.mu.Unlock()
	log.Printf("[events] client connected (total: %d)", len(b.clients))
}

func (b *Broker) unregister(c *client) {
	b.mu.Lock()
	if _, ok := b.clients[c]; ok {
		delete(b.clients, c)
		c.conn.Close()
		log.Printf("[events] client disconnected (total: %d)", len(b.clients))
	}
	b.mu.Unlock()
}

func (b *Broker) broadcast(data []byte) {
	b.mu.RLock()
	var failed []*client
	for c := range b.clients {
		c.mu.Lock()
		err := c.conn.WriteMessage(websocket.TextMessage, data)
		c.mu.Unlock()
		if err != nil {
			failed = append(failed, c)
		}
	}
	b.mu.RUnlock()
	for _, c := range failed {
		b.unregister(c)
	}
}

// Start subscribes the relay to every bus fact. No-op-safe; called from main.
var once sync.Once

func Start() {
	once.Do(func() {
		bus.Subscribe("*:*", func(e bus.Event) {
			var payload json.RawMessage
			if e.Payload != nil {
				payload, _ = json.Marshal(e.Payload)
			}
			wire, err := json.Marshal(struct {
				ID      string          `json:"id"`
				At      time.Time       `json:"at"`
				Topic   string          `json:"topic"`
				UserID  string          `json:"user_id"`
				Payload json.RawMessage `json:"payload"`
			}{e.ID, e.At, e.Topic, e.UserID, payload})
			if err != nil {
				return
			}
			DefaultBroker.broadcast(wire)
		})
	})
}

func HandleEvents(w http.ResponseWriter, r *http.Request) {
	token := r.URL.Query().Get("token")
	if token == "" {
		token = strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer ")
	}
	if token == "" {
		http.Error(w, "Missing token", http.StatusUnauthorized)
		return
	}
	if _, ok := middleware.ValidateToken("Bearer " + token); !ok {
		http.Error(w, "Invalid token", http.StatusUnauthorized)
		return
	}

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("[events] upgrade failed: %v", err)
		return
	}

	c := &client{conn: conn}
	DefaultBroker.register(c)
	defer DefaultBroker.unregister(c)

	for {
		if _, _, err := conn.ReadMessage(); err != nil {
			break
		}
		// Clients are receive-only; drain any input so the conn stays healthy.
	}
}