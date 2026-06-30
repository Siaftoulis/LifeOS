package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"

	"tailscale.com/tsnet"
)

// InitTailnet initializes the embedded Tailscale mesh network listener.
func InitTailnet(hostname string, port int, appMux *http.ServeMux) error {
	dir, err := filepath.Abs("./tsnet-state")
	if err != nil {
		return fmt.Errorf("failed to resolve absolute state path: %w", err)
	}

	controlURL := os.Getenv("TAILSCALE_CONTROL_URL")
	if controlURL == "" {
		controlURL = "http://109.242.136.196:8090" // Default fallback if needed, or could return error
	}

	s := &tsnet.Server{
		Hostname:   hostname,
		Dir:        dir,
		Logf:       log.Printf,
		ControlURL: controlURL,
	}

	ln, err := s.Listen("tcp", fmt.Sprintf(":%d", port))
	if err != nil {
		return fmt.Errorf("tailnet offline or bind failed: %w", err)
	}

	authMiddleware := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		lc, err := s.LocalClient()
		if err != nil {
			http.Error(w, "Tailnet client error", http.StatusInternalServerError)
			return
		}
		info, err := lc.WhoIs(r.Context(), r.RemoteAddr)
		if err != nil {
			http.Error(w, "Unauthorized: Tailnet identity verification failed", http.StatusUnauthorized)
			return
		}

		// Optional: you can pass the identity down to handlers using headers
		r.Header.Set("X-Tailnet-User", info.UserProfile.LoginName)

		// Serve the actual application
		appMux.ServeHTTP(w, r)
	})

	log.Printf("Mesh Active: Node [%s] securely listening on Tailnet :%d", hostname, port)
	go http.Serve(ln, authMiddleware)
	return nil
}
