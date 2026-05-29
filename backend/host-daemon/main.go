package main

import (
	"log"
	"net/http"
)

func main() {
	// Register the remote action handler
	http.HandleFunc("/api/v1/action", handleAction)

	// Configure loop port (defaulting to 50051 for internal relay mesh)
	port := ":50051"
	log.Printf("LifeOS Host Daemon starting background loop on port %s", port)
	
	// Start the background server loop
	if err := http.ListenAndServe(port, nil); err != nil {
		log.Fatalf("Host Daemon execution failed: %v", err)
	}
}
