package markdown

import (
	"log"
	"net/http"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // Allowing all origins for local dev
	},
}

func HandleCollab(w http.ResponseWriter, r *http.Request) {
	docID := r.URL.Query().Get("doc_id")
	if docID == "" {
		http.Error(w, "Missing doc_id", http.StatusBadRequest)
		return
	}

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Upgrade failed:", err)
		return
	}
	defer conn.Close()

	log.Printf("Client connected to collab session for doc: %s", docID)

	// Stub: Echo OT/CRDT deltas to other active connections.
	for {
		messageType, message, err := conn.ReadMessage()
		if err != nil {
			log.Println("Collab connection closed:", err)
			break
		}

		// Currently just echoes back. Real implementation would route to hub.
		if err := conn.WriteMessage(messageType, message); err != nil {
			log.Println("Failed to broadcast message:", err)
			break
		}
	}
}
