package location

import (
	"log"
	"net/http"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true }, // Enforce boundary via Tailnet implicitly
}

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/ws/location", func(w http.ResponseWriter, r *http.Request) {
		conn, err := upgrader.Upgrade(w, r, nil)
		if err != nil {
			log.Printf("WebSocket upgrade failed: %v", err)
			return
		}
		defer conn.Close()

		for {
			var msg map[string]interface{}
			err := conn.ReadJSON(&msg)
			if err != nil {
				log.Printf("Location WS read error: %v", err)
				break
			}
			log.Printf("Live Tracking Beacon: %v", msg)
			// Future: Pipe into TSDB or live visualization stream
		}
	})
}
