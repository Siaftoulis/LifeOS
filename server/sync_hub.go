package main

// ponytail: stateless relay — binary passthrough for room-based Yjs CRDT & awareness payloads

import (
	"encoding/json"
	"log"
	"net/http"
	"strings"
	"sync"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

type Client struct {
	hub    *Hub
	conn   *websocket.Conn
	send   chan []byte
	userID string
}

type RoomMessage struct {
	sender *Client
	data   []byte
	room   string
}

type Hub struct {
	clients    map[*Client]bool
	broadcast  chan RoomMessage
	register   chan *Client
	unregister chan *Client
	sync.RWMutex
}

func newHub() *Hub {
	return &Hub{
		broadcast:  make(chan RoomMessage),
		register:   make(chan *Client),
		unregister: make(chan *Client),
		clients:    make(map[*Client]bool),
	}
}

func (h *Hub) run() {
	for {
		select {
		case client := <-h.register:
			h.Lock()
			h.clients[client] = true
			h.Unlock()
		case client := <-h.unregister:
			h.Lock()
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				close(client.send)
			}
			h.Unlock()
		case msg := <-h.broadcast:
			h.RLock()
			for client := range h.clients {
				// Don't echo back to sender
				if client == msg.sender {
					continue
				}

				// Check ACL permission if a room is specified
				if msg.room != "" && !hasPermission(client.userID, msg.room, "read") {
					continue
				}

				select {
				case client.send <- msg.data:
				default:
					close(client.send)
					delete(h.clients, client)
				}
			}
			h.RUnlock()
		}
	}
}

func (c *Client) readPump() {
	defer func() {
		c.hub.unregister <- c
		c.conn.Close()
	}()
	for {
		_, message, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("error: %v", err)
			}
			break
		}

		var payload map[string]interface{}
		room := ""
		if err := json.Unmarshal(message, &payload); err == nil {
			if r, ok := payload["room"].(string); ok {
				room = r
			}
		}

		// Enforce write permission for posting to room
		if room != "" && !hasPermission(c.userID, room, "write") {
			log.Printf("Permission denied for user %s on room %s", c.userID, room)
			continue
		}

		c.hub.broadcast <- RoomMessage{
			sender: c,
			data:   message,
			room:   room,
		}
	}
}

func (c *Client) writePump() {
	defer func() {
		c.conn.Close()
	}()
	for message := range c.send {
		w, err := c.conn.NextWriter(websocket.TextMessage)
		if err != nil {
			return
		}
		w.Write(message)

		if err := w.Close(); err != nil {
			return
		}
	}
	c.conn.WriteMessage(websocket.CloseMessage, []byte{})
}

func serveWs(hub *Hub, w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println(err)
		return
	}

	userID := "anonymous"
	authHeader := r.Header.Get("Authorization")
	if authHeader != "" && strings.HasPrefix(authHeader, "Bearer ") {
		token := strings.TrimPrefix(authHeader, "Bearer ")
		if token != "" {
			userID = token
		}
	} else if tokenParam := r.URL.Query().Get("token"); tokenParam != "" {
		userID = tokenParam
	}

	client := &Client{
		hub:    hub,
		conn:   conn,
		send:   make(chan []byte, 256),
		userID: userID,
	}
	client.hub.register <- client

	go client.writePump()
	go client.readPump()
}
