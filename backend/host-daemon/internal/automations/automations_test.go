package automations

import (
	"testing"
	"time"

	"lifeos/host-daemon/internal/bus"
	"lifeos/host-daemon/internal/movies"
	"lifeos/host-daemon/internal/points"
)

// End-to-end: publish → bus → rule → points ledger. Runs in this package's
// own ./data dir so the daemon's real ledger is never touched.
func TestMovieWatchedAwardsPoints(t *testing.T) {
	Register()
	bus.Publish(bus.Event{
		Topic:   "movies:watched",
		UserID:  "kid1",
		Payload: movies.WatchedEvent{MovieID: "m1", Title: "Dune", UserID: "kid1"},
	})

	deadline := time.Now().Add(2 * time.Second)
	for points.GetBalance("kid1") == 0 && time.Now().Before(deadline) {
		time.Sleep(5 * time.Millisecond)
	}
	if got := points.GetBalance("kid1"); got != 10 {
		t.Fatalf("expected +10 points after watching, got %d", got)
	}
}