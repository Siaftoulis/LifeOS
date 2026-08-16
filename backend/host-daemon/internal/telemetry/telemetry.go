// Package telemetry ingests obfuscated activity packets from clients and
// awards points — the server decides everything: what an event is worth
// (rules below), whether it's a replay (dedup), and the daily cap (points
// module). Clients never send point amounts, only "something happened".
//
// ponytail: XOR+base64 is obfuscation, not encryption — a determined client
// can decode it. That's fine: the rules table is the real integrity boundary,
// and the client is the owner's own device on the owner's own network.
package telemetry

import (
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"

	"lifeos/host-daemon/internal/auth/middleware"
	"lifeos/host-daemon/internal/points"
)

const xorKey = "lifeos-tel-2026-x"

// event is one client activity, decoded from a packet entry.
type event struct {
	Module string         `json:"module"`
	Action string         `json:"action"`
	Data   map[string]any `json:"data"`
	Ts     int64          `json:"ts"`
}

// rules: module:action → points. Single source of truth for what activity
// earns. Add a row here and the client hook in one place; nothing else.
var rules = map[string]int{
	"engine:entity_created":   5,
	"home:device_toggled":     1,
	"flashcards:deck_created": 10,
	"movies:watchlist_added":  5,
	"movies:review_added":     10,
	"movies:status_changed":   2,
	"zen:note_synced":         1,
	"books:progress_saved":    2,
	"books:highlight_added":   3,
	"books:downloaded":        5,
	"books:ai_described":      3,
	"books:ai_summarized":     3,
	"books:ai_chatted":        1,
	"vm:toggled":              2,
	"music:track_streamed":    1,
	"music:lyrics_studied":    2,
	"music:download_started":  3,
	"youtube:download_started": 3,
	"backup:uploaded":          10,
	"voice:parsed":             2,
	"markdown:synced":          1,
}

// decodeEvent reverses the client encoding: base64url(xor(json)).
func decodeEvent(encoded string) (event, error) {
	raw, err := base64.URLEncoding.DecodeString(encoded)
	if err != nil {
		return event{}, err
	}
	key := []byte(xorKey)
	for i := range raw {
		raw[i] ^= key[i%len(key)]
	}
	var ev event
	if err := json.Unmarshal(raw, &ev); err != nil {
		return event{}, err
	}
	return ev, nil
}

// Replay protection: one dedup key per (user, event, day) so a resent packet
// can't double-award. The day is part of the key, so real repeated activity
// on later days still counts.
var (
	dedupMu   sync.Mutex
	dedupSeen = map[string]bool{}
)

func dedupKey(username string, ev event) string {
	day := time.Unix(ev.Ts, 0).Format("2006-01-02")
	blob, _ := json.Marshal(ev.Data) // Go marshals maps with sorted keys
	h := sha256.Sum256([]byte(fmt.Sprintf("%s|%s|%s|%s|%s", username, ev.Module, ev.Action, day, blob)))
	return hex.EncodeToString(h[:])
}

func seen(key string) bool {
	dedupMu.Lock()
	defer dedupMu.Unlock()
	if dedupSeen[key] {
		return false
	}
	if len(dedupSeen) > 5000 { // one day's worth; keys are day-scoped
		dedupSeen = map[string]bool{}
	}
	dedupSeen[key] = true
	return true
}

// RegisterRoutes mounts the telemetry ingest.
func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/telemetry/batch", HandleBatch)
}

// HandleBatch: POST {"packet": ["<encoded>", ...]} — small packets, server
// decodes, validates against rules, dedups and awards points itself.
func HandleBatch(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	username, _ := r.Context().Value(middleware.UserContextKey).(string)
	if username == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	var payload struct {
		Packet []string `json:"packet"`
	}
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		http.Error(w, "Invalid payload", http.StatusBadRequest)
		return
	}

	awarded := 0
	for _, enc := range payload.Packet {
		ev, err := decodeEvent(enc)
		if err != nil {
			log.Printf("[telemetry] dropped undecodable event from %s", username)
			continue
		}
		pts, ok := rules[ev.Module+":"+ev.Action]
		if !ok {
			continue // unknown activity: ignored, never rewarded
		}
		if !seen(dedupKey(username, ev)) {
			continue
		}
		points.AddPointsWithEvent(username, pts, "Telemetry: "+ev.Module+":"+ev.Action)
		awarded++
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  "ok",
		"awarded": awarded,
		"balance": points.GetBalance(username),
	})
}