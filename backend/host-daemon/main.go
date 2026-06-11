package main

import (
	"log"
	"net/http"
	"lifeos/host-daemon/internal/sync"
	"lifeos/host-daemon/internal/markdown"
	"lifeos/host-daemon/internal/media"
	"lifeos/host-daemon/internal/location"
	"lifeos/host-daemon/internal/system"
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/api/v1/action", handleAction)
	
	sync.RegisterRoutes(mux)
	markdown.RegisterRoutes(mux, "./data/markdown")
	media.RegisterRoutes(mux, "./data/media")
	location.RegisterRoutes(mux)
	system.RegisterRoutes(mux)

	port := ":50051"
	log.Printf("LifeOS Host Daemon starting background loop on port %s", port)
	
	if err := http.ListenAndServe(port, mux); err != nil {
		log.Fatalf("Host Daemon execution failed: %v", err)
	}
}
