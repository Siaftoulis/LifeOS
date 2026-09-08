package music

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestSlskdIsAvailable_Offline(t *testing.T) {
	client := &SlskdClient{
		BaseURL:    "http://127.0.0.1:59999", // Unused port
		HTTPClient: &http.Client{Timeout: 300 * time.Millisecond},
	}
	ctx, cancel := context.WithTimeout(context.Background(), 500*time.Millisecond)
	defer cancel()

	if client.IsAvailable(ctx) {
		t.Errorf("expected IsAvailable to be false for dead endpoint")
	}
}

func TestSlskdSearchAndEnqueue_Mock(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch {
		case r.URL.Path == "/api/v0/session":
			w.WriteHeader(http.StatusOK)
			_, _ = w.Write([]byte(`{"username":"lifeos_user"}`))

		case r.URL.Path == "/api/v0/searches" && r.Method == http.MethodPost:
			w.WriteHeader(http.StatusOK)
			_, _ = w.Write([]byte(`{"id":"search-abc-123"}`))

		case r.URL.Path == "/api/v0/searches/search-abc-123/responses":
			w.WriteHeader(http.StatusOK)
			resp := []map[string]interface{}{
				{
					"username":        "audiophile_peer",
					"uploadSpeed":     10485760, // 10MB/s
					"freeUploadSlots": 2,
					"files": []map[string]interface{}{
						{
							"filename":   "Daft Punk - One More Time.flac",
							"size":       42589120,
							"bitRate":    950,
							"sampleRate": 44100,
							"bitDepth":   16,
							"extension":  "flac",
						},
					},
				},
			}
			_ = json.NewEncoder(w).Encode(resp)

		case r.URL.Path == "/api/v0/transfers/downloads/audiophile_peer" && r.Method == http.MethodPost:
			w.WriteHeader(http.StatusOK)
			_, _ = w.Write([]byte(`{"status":"enqueued"}`))

		default:
			http.NotFound(w, r)
		}
	}))
	defer server.Close()

	client := &SlskdClient{
		BaseURL:    server.URL,
		HTTPClient: server.Client(),
	}

	ctx, cancel := context.WithTimeout(context.Background(), 4*time.Second)
	defer cancel()

	if !client.IsAvailable(ctx) {
		t.Fatalf("expected client to be available against mock server")
	}

	match, err := client.SearchFLAC(ctx, "Daft Punk", "One More Time")
	if err != nil {
		t.Fatalf("unexpected search error: %v", err)
	}

	if match == nil {
		t.Fatalf("expected match, got nil")
	}

	if match.Username != "audiophile_peer" || match.Filename != "Daft Punk - One More Time.flac" {
		t.Errorf("unexpected match fields: %+v", match)
	}

	if !match.SlotsFree {
		t.Errorf("expected SlotsFree to be true")
	}

	if err := client.EnqueueDownload(ctx, match); err != nil {
		t.Fatalf("failed to enqueue download: %v", err)
	}
}
