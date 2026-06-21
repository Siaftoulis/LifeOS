package main

import (
	"log"
	"net/http"
	"lifeos/host-daemon/internal/sync"
	"lifeos/host-daemon/internal/markdown"
	"lifeos/host-daemon/internal/media"
	"lifeos/host-daemon/internal/location"
	"lifeos/host-daemon/internal/system"
	"lifeos/host-daemon/internal/accounting"
	"lifeos/host-daemon/internal/banking"
	"lifeos/host-daemon/internal/books"
	"lifeos/host-daemon/internal/voice"
	"lifeos/host-daemon/internal/calendar"
	"lifeos/host-daemon/internal/cloud"
	"lifeos/host-daemon/internal/sandbox"
	"lifeos/host-daemon/internal/darkweb"
	"lifeos/host-daemon/internal/flashcards"
	"lifeos/host-daemon/internal/home"
	"lifeos/host-daemon/internal/auth"
	"lifeos/host-daemon/internal/kb"
	"lifeos/host-daemon/internal/movies"
	"lifeos/host-daemon/internal/music"
	"lifeos/host-daemon/internal/gallery"
	"lifeos/host-daemon/internal/points"
	"lifeos/host-daemon/internal/infinity"
	"lifeos/host-daemon/internal/vm"
	"lifeos/host-daemon/internal/youtube"
	"lifeos/host-daemon/internal/devsim"
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/api/v1/action", handleAction)
	
	sync.RegisterRoutes(mux)
	markdown.RegisterRoutes(mux, "./data/markdown")
	media.RegisterRoutes(mux, "./data/media")
	location.RegisterRoutes(mux)
	system.RegisterRoutes(mux)
	accounting.RegisterRoutes(mux, "./data/accounting")
	banking.RegisterRoutes(mux)
	books.RegisterRoutes(mux)
	voice.RegisterRoutes(mux)
	calendar.RegisterRoutes(mux)
	cloud.RegisterRoutes(mux)
	sandbox.RegisterRoutes(mux)
	darkweb.RegisterRoutes(mux)
	flashcards.RegisterRoutes(mux)
	home.RegisterRoutes(mux)
	auth.RegisterRoutes(mux)
	kb.RegisterRoutes(mux)
	movies.RegisterRoutes(mux)
	music.RegisterRoutes(mux)
	gallery.RegisterRoutes(mux)
	points.RegisterRoutes(mux)
	infinity.RegisterRoutes(mux)
	vm.RegisterRoutes(mux)
	youtube.RegisterRoutes(mux)
	devsim.RegisterRoutes(mux)

	port := ":50051"
	log.Printf("LifeOS Host Daemon starting background loop on port %s", port)
	
	// Start the Custom DDNS Updater routine
	go startCustomDDNSUpdater()
	
	if err := InitTailnet("lifeos-host", 50051, mux); err != nil {
		log.Printf("Tailnet init error: %v", err)
	}
	
	if err := http.ListenAndServe(port, mux); err != nil {
		log.Fatalf("Host Daemon execution failed: %v", err)
	}
}
