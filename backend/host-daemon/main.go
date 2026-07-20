package main

import (
	"lifeos/host-daemon/internal/accounting"
	"lifeos/host-daemon/internal/auth"
	"lifeos/host-daemon/internal/backup"
	"lifeos/host-daemon/internal/banking"
	"lifeos/host-daemon/internal/books"
	"lifeos/host-daemon/internal/calendar"
	"lifeos/host-daemon/internal/cloud"
	"lifeos/host-daemon/internal/darkweb"
	"lifeos/host-daemon/internal/devsim"
	"lifeos/host-daemon/internal/flashcards"
	"lifeos/host-daemon/internal/gallery"
	"lifeos/host-daemon/internal/home"
	"lifeos/host-daemon/internal/illness"
	"lifeos/host-daemon/internal/infinity"
	"lifeos/host-daemon/internal/kb"
	"lifeos/host-daemon/internal/knowledge"
	"lifeos/host-daemon/internal/location"
	"lifeos/host-daemon/internal/markdown"
	"lifeos/host-daemon/internal/media"
	"lifeos/host-daemon/internal/movies"
	"lifeos/host-daemon/internal/music"
	"lifeos/host-daemon/internal/player"
	"lifeos/host-daemon/internal/points"
	"lifeos/host-daemon/internal/sandbox"
	"lifeos/host-daemon/internal/sync"
	"lifeos/host-daemon/internal/system"
	"lifeos/host-daemon/internal/vm"
	"lifeos/host-daemon/internal/voice"
	"lifeos/host-daemon/internal/youtube"
	"lifeos/host-daemon/internal/engine"
	"log"
	"net/http"
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/api/v1/action", handleAction)

	if err := gallery.InitDB("./data"); err != nil {
		log.Printf("Gallery DB init error: %v", err)
	}

	if err := movies.InitDB("./data"); err != nil {
		log.Printf("Movies DB init error: %v", err)
	}

	if err := books.InitDB("./data"); err != nil {
		log.Printf("Books DB init error: %v", err)
	}

	if err := banking.InitDB("./data"); err != nil {
		log.Printf("Banking DB init error: %v", err)
	}

	if err := player.InitDB("./data"); err != nil {
		log.Printf("Player DB init error: %v", err)
	}

	if err := knowledge.InitDB("./data"); err != nil {
		log.Printf("Knowledge DB init error: %v", err)
	}

	if err := flashcards.InitDB("./data"); err != nil {
		log.Printf("Flashcards DB init error: %v", err)
	}

	if err := music.InitDB("./data"); err != nil {
		log.Printf("Music DB init error: %v", err)
	}

	if err := home.InitDB("./data"); err != nil {
		log.Printf("Home DB init error: %v", err)
	}

	if err := infinity.InitDB("./data"); err != nil {
		log.Printf("Infinity DB init error: %v", err)
	}

	if err := backup.InitDB("./data"); err != nil {
		log.Printf("Backup DB init error: %v", err)
	}

	if err := darkweb.InitDB("./data"); err != nil {
		log.Printf("Darkweb DB init error: %v", err)
	}

	if err := vm.InitDB("./data"); err != nil {
		log.Printf("VM DB init error: %v", err)
	}

	if err := voice.InitDB("./data"); err != nil {
		log.Printf("Voice DB init error: %v", err)
	}

	if err := youtube.InitDB("./data"); err != nil {
		log.Printf("YouTube DB init error: %v", err)
	}

	if err := system.InitDB("./data"); err != nil {
		log.Printf("System DB init error: %v", err)
	}

	if err := sync.InitDB("./data"); err != nil {
		log.Printf("Sync DB init error: %v", err)
	}

	if err := sandbox.InitDB("./data"); err != nil {
		log.Printf("Sandbox DB init error: %v", err)
	}

	if err := devsim.InitDB("./data"); err != nil {
		log.Printf("DevSim DB init error: %v", err)
	}

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
	backup.RegisterRoutes(mux)
	points.RegisterRoutes(mux)
	infinity.RegisterRoutes(mux)
	vm.RegisterRoutes(mux)
	youtube.RegisterRoutes(mux)
	devsim.RegisterRoutes(mux)
	illness.RegisterRoutes(mux)
	player.RegisterRoutes(mux)
	knowledge.RegisterRoutes(mux)
	engine.RegisterRoutes(mux)

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
