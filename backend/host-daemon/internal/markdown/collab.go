package markdown

import (
	"log"
	"net/http"
	"strings"
	"sync"

	"lifeos/host-daemon/internal/auth/middleware"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // Allowing all origins for local dev
	},
}


// Hub maintains the set of active clients and broadcasts messages to the clients.
type Hub struct {
	clients    map[*websocket.Conn]bool
	broadcast  chan []byte
	register   chan *websocket.Conn
	unregister chan *websocket.Conn
	mu         sync.Mutex
}

var docHubs = make(map[string]*Hub)
var hubsMu sync.Mutex

func getHub(docID string) *Hub {
	hubsMu.Lock()
	defer hubsMu.Unlock()
	h, ok := docHubs[docID]
	if !ok {
		h = &Hub{
			broadcast:  make(chan []byte),
			register:   make(chan *websocket.Conn),
			unregister: make(chan *websocket.Conn),
			clients:    make(map[*websocket.Conn]bool),
		}
		docHubs[docID] = h
		go h.run()
	}
	return h
}

func (h *Hub) run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			h.clients[client] = true
			h.mu.Unlock()
		case client := <-h.unregister:
			h.mu.Lock()
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				client.Close()
			}
			h.mu.Unlock()
		case message := <-h.broadcast:
			h.mu.Lock()
			for client := range h.clients {
				err := client.WriteMessage(websocket.TextMessage, message)
				if err != nil {
					client.Close()
					delete(h.clients, client)
				}
			}
			h.mu.Unlock()
		}
	}
}

func HandleCollab(w http.ResponseWriter, r *http.Request) {
	docID := r.URL.Query().Get("doc_id")
	if docID == "" {
		http.Error(w, "Missing doc_id", http.StatusBadRequest)
		return
	}

	// Collab websockets carry the JWT as query param (browser WebSocket can't
	// set headers); the auth gate skips this path, so we validate here.
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
		log.Println("Upgrade failed:", err)
		return
	}

	hub := getHub(docID)
	hub.register <- conn

	log.Printf("Client connected to collab session for doc: %s", docID)

	defer func() {
		hub.unregister <- conn
	}()

	for {
		_, message, err := conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("error: %v", err)
			}
			break
		}
		hub.broadcast <- message
	}
}
