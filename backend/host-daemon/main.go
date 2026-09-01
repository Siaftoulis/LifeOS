package main

import (
	"encoding/json"
	"lifeos/host-daemon/internal/accounting"
	"lifeos/host-daemon/internal/auth"
	"lifeos/host-daemon/internal/auth/middleware"
	"lifeos/host-daemon/internal/automations"
	"lifeos/host-daemon/internal/backup"
	"lifeos/host-daemon/internal/banking"
	"lifeos/host-daemon/internal/books"
	"lifeos/host-daemon/internal/calendar"
	"lifeos/host-daemon/internal/chat"
	"lifeos/host-daemon/internal/chtm"
	"lifeos/host-daemon/internal/cloud"
	"lifeos/host-daemon/internal/darkweb"
	"lifeos/host-daemon/internal/devsim"
	"lifeos/host-daemon/internal/engine"
	"lifeos/host-daemon/internal/events"
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
	"lifeos/host-daemon/internal/notes"
	"lifeos/host-daemon/internal/oauth"
	"lifeos/host-daemon/internal/player"
	"lifeos/host-daemon/internal/points"
	"lifeos/host-daemon/internal/prayers"
	"lifeos/host-daemon/internal/sandbox"
	"lifeos/host-daemon/internal/sync"
	"lifeos/host-daemon/internal/system"
	"lifeos/host-daemon/internal/vm"
	"lifeos/host-daemon/internal/voice"
	"lifeos/host-daemon/internal/youtube"
	"lifeos/host-daemon/internal/zen"
	"lifeos/host-daemon/internal/telemetry"
	"log"
	"net/http"
	"os"
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

	if err := engine.InitDB("./data"); err != nil {
		log.Printf("Engine DB init error: %v", err)
	}

	if err := sandbox.InitDB("./data"); err != nil {
		log.Printf("Sandbox DB init error: %v", err)
	}

	if err := devsim.InitDB("./data"); err != nil {
		log.Printf("DevSim DB init error: %v", err)
	}

	if err := zen.InitDB("./data"); err != nil {
		log.Printf("Zen DB init error: %v", err)
	}

	if err := prayers.InitDB("./data"); err != nil {
		log.Printf("Prayers DB init error: %v", err)
	}

	if err := chat.InitDB("./data"); err != nil {
		log.Printf("Chat DB init error: %v", err)
	}

	sync.RegisterRoutes(mux)
	chat.RegisterRoutes(mux)
	markdown.RegisterRoutes(mux, "./data/markdown")
	notes.RegisterRoutes(mux, "./vault")
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
	chtm.RegisterRoutes(mux)
	points.RegisterRoutes(mux)
	infinity.RegisterRoutes(mux)
	vm.RegisterRoutes(mux)
	youtube.RegisterRoutes(mux)
	devsim.RegisterRoutes(mux)
	illness.RegisterRoutes(mux)
	player.RegisterRoutes(mux)
	knowledge.RegisterRoutes(mux)
	engine.RegisterRoutes(mux)
	zen.RegisterRoutes(mux)
	telemetry.RegisterRoutes(mux)
	prayers.RegisterRoutes(mux)

	// The ecosystem brain: every cross-domain rule lives here. Publishing
	// modules never know their listeners; listeners never know each other.
	automations.Register()

	// Push every bus fact to connected clients (app + web portal).
	events.Start()
	mux.HandleFunc("/api/v1/events", events.HandleEvents)

	// OAuth SSO (GitHub/Google) for family members; 503 if not configured
	mux.HandleFunc("/api/v1/auth/oauth/providers", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(oauth.EnabledProviders())
	})
	for _, p := range []string{"github", "google"} {
		mux.HandleFunc("/api/v1/auth/oauth/"+p+"/start", oauth.HandleStart(p))
		mux.HandleFunc("/api/v1/auth/oauth/"+p+"/callback", oauth.HandleCallback(p))
	}

	mux.HandleFunc("/api/v1/ping", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{
			"status":  "ok",
			"server":  "lifeos-host-daemon",
			"version": "1.5.0",
		})
	})

	// Web portal: family browser access (login + modules) served at /
	fileServer := http.FileServer(http.Dir("./web"))
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cache-Control", "no-cache, no-store, must-revalidate")
		w.Header().Set("Pragma", "no-cache")
		w.Header().Set("Expires", "0")
		fileServer.ServeHTTP(w, r)
	})

	// ponytail: global auth gate. Every /api/ route requires a valid JWT except
	// login, register (public by design), the OAuth entry points and the collab
	// websocket (browsers can't set WS headers; HandleCollab validates the
	// ?token= query param itself).
	handler := middleware.WithAuthGate([]string{
		"/api/v1/ping",
		"/api/v1/auth/login",
		"/api/v1/auth/register",
		"/api/v1/auth/oauth/providers",
		"/api/v1/auth/oauth/github/start",
		"/api/v1/auth/oauth/github/callback",
		"/api/v1/auth/oauth/google/start",
		"/api/v1/auth/oauth/google/callback",
		"/api/markdown/collab",
		"/api/v1/events", // WS: validates ?token= / Bearer itself
		"/api/v1/radar/live", // WS: radar live coordinates
		"/api/v1/music/*",
		"/api/v1/prayers/*",
		"/api/v1/gallery/*",
		"/api/v1/system/updates/*",
	}, mux)

	// ponytail: Funnel upstream — public traffic arrives here via Tailscale
	// Funnel (RemoteAddr looks like a tailnet peer), so password auth and
	// self-registration are explicitly denied on this path. The web portal
	// uses OAuth exclusively.
	publicOnly := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/api/v1/auth/register" {
			http.Error(w, "Registration is invite-only (admin creates accounts)", http.StatusForbidden)
			return
		}
		if r.URL.Path == "/api/v1/auth/login" {
			http.Error(w, "Password login is disabled from the public internet (use OAuth)", http.StatusForbidden)
			return
		}
		handler.ServeHTTP(w, r)
	})
	go func() {
		if err := http.ListenAndServe("127.0.0.1:50052", publicOnly); err != nil {
			log.Printf("Funnel upstream listener error: %v", err)
		}
	}()

	port := ":50051"
	log.Printf("LifeOS Host Daemon starting background loop on port %s", port)

	// Start the Custom DDNS Updater routine
	go startCustomDDNSUpdater()

	// ponytail: LIFEOS_LOCAL_ONLY=1 skips the embedded Tailscale listener
	// (needs control server login); serve plain HTTP on :50051 instead.
	if os.Getenv("LIFEOS_LOCAL_ONLY") != "1" {
		if err := InitTailnet("lifeos-host", 50051, handler); err != nil {
			log.Printf("Tailnet init error: %v", err)
		}
	}

	if err := http.ListenAndServe(port, handler); err != nil {
		log.Fatalf("Host Daemon execution failed: %v", err)
	}
}
