package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"tailscale.com/ipn"
	"tailscale.com/tsnet"
)

// InitTailnet initializes the embedded Tailscale mesh network listener.
func InitTailnet(hostname string, port int, app http.Handler) error {
	dir, err := filepath.Abs("./tsnet-state")
	if err != nil {
		return fmt.Errorf("failed to resolve absolute state path: %w", err)
	}

	controlURL := os.Getenv("CONTROL_URL")
	if controlURL == "" {
		controlURL = "https://controlplane.tailscale.com"
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
			http.Error(w, "Unauthorized: Tailnet client error", http.StatusUnauthorized)
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
		app.ServeHTTP(w, r)
	})

	log.Printf("Mesh Active: Node [%s] securely listening on Tailnet :%d", hostname, port)
	go http.Serve(ln, authMiddleware)
	go enableFunnel(s)
	return nil
}

// enableFunnel: public HTTPS endpoint on 443 → localhost:50052, so the site is
// reachable from any browser (work PCs etc.) at https://<node>.<tailnet>.ts.net.
// Requires "HTTPS Certificates" enabled in the tailnet admin console.
func enableFunnel(s *tsnet.Server) {
	lc, err := s.LocalClient()
	if err != nil {
		log.Printf("Funnel: LocalClient error: %v", err)
		return
	}

	dnsName := ""
	for attempt := 0; attempt < 12 && dnsName == ""; attempt++ {
		ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
		status, err := lc.Status(ctx)
		cancel()
		if err != nil {
			log.Printf("Funnel: Status error (attempt %d): %v", attempt+1, err)
		} else if status.BackendState == "Running" && status.Self != nil && status.Self.DNSName != "" {
			dnsName = strings.TrimSuffix(status.Self.DNSName, ".")
			break
		} else {
			state := status.BackendState
			if state == "" && status.Self == nil {
				state = "unknown"
			}
			log.Printf("Funnel: waiting for backend (attempt %d, state=%s)", attempt+1, state)
		}
		time.Sleep(10 * time.Second)
	}
	if dnsName == "" {
		log.Printf("Funnel: tailnet backend never reached Running state")
		return
	}

	hp := ipn.HostPort(dnsName + ":443")
	cfg := &ipn.ServeConfig{
		TCP: map[uint16]*ipn.TCPPortHandler{
			443: {HTTPS: true},
		},
		Web: map[ipn.HostPort]*ipn.WebServerConfig{
			hp: {Handlers: map[string]*ipn.HTTPHandler{
				"/": {Proxy: "http://127.0.0.1:50052/"},
			}},
		},
		AllowFunnel: map[ipn.HostPort]bool{hp: true},
	}
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	if err := lc.SetServeConfig(ctx, cfg); err != nil {
		log.Printf("Funnel: SetServeConfig error (is HTTPS Certificates enabled in the tailnet admin console?): %v", err)
		return
	}
	log.Printf("Funnel active: public URL https://%s", dnsName)
}
