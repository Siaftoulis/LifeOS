package main

import (
	"fmt"
	"log"
	"net/http"
	"path/filepath"

	"tailscale.com/tsnet"
)

// InitTailnet initializes the embedded Tailscale mesh network listener.
func InitTailnet(hostname string, port int, appMux *http.ServeMux) error {
	dir, err := filepath.Abs("./tsnet-state")
	if err != nil {
		return fmt.Errorf("failed to resolve absolute state path: %w", err)
	}

	s := &tsnet.Server{
		Hostname:   hostname,
		Dir:        dir,
		Logf:       log.Printf, // Output engine noise to see auth link
		ControlURL: "http://109.242.136.196:8090",
	}

	ln, err := s.Listen("tcp", fmt.Sprintf(":%d", port))
	if err != nil {
		return fmt.Errorf("tailnet offline or bind failed: %w", err)
	}

	authMiddleware := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		lc, _ := s.LocalClient()
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
