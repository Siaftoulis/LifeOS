package main

import (
	"fmt"
	"log"
	"net/http"
	"path/filepath"

	"tailscale.com/tsnet"
)

// InitTailnet initializes the embedded Tailscale mesh network listener.
func InitTailnet(hostname string, port int) error {
	dir, err := filepath.Abs("./tsnet-state")
	if err != nil {
		return fmt.Errorf("failed to resolve absolute state path: %w", err)
	}

	s := &tsnet.Server{
		Hostname: hostname,
		Dir:      dir,
		Logf:     func(format string, args ...any) {}, // Silence engine noise
	}

	ln, err := s.Listen("tcp", fmt.Sprintf(":%d", port))
	if err != nil {
		return fmt.Errorf("tailnet offline or bind failed: %w", err)
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		lc, _ := s.LocalClient()
		info, err := lc.WhoIs(r.Context(), r.RemoteAddr)
		if err != nil {
			http.Error(w, "Unauthorized: Tailnet identity verification failed", http.StatusUnauthorized)
			return
		}
		// Validated request
		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, "Verified Node Identity: %s", info.UserProfile.LoginName)
	})

	log.Printf("Mesh Active: Node [%s] securely listening on Tailnet :%d", hostname, port)
	go http.Serve(ln, mux)
	return nil
}
