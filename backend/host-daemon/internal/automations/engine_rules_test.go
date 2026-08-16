package automations

import (
	"os"
	"testing"
	"time"

	"lifeos/host-daemon/internal/bus"
	"lifeos/host-daemon/internal/engine"
	"lifeos/host-daemon/internal/points"
)

func entity(id, typ string, payload map[string]interface{}) engine.Entity {
	now := time.Now()
	return engine.Entity{
		ID:        id,
		Type:      engine.EntityType(typ),
		CreatorID: "finuser",
		Payload:   payload,
		CreatedAt: now,
		UpdatedAt: now,
	}
}

func waitBalance(user string, want int) int {
	deadline := time.Now().Add(2 * time.Second)
	for points.GetBalance(user) != want && time.Now().Before(deadline) {
		time.Sleep(5 * time.Millisecond)
	}
	return points.GetBalance(user)
}

// Finance Hub awards: paid bill +20, expense +5, income +10, budget +15.
// Delta-based so it survives leftover state in the package ./data dir, and it
// cleans up so repeat runs (and the movie test) start fresh.
func TestFinanceAwardsPoints(t *testing.T) {
	Register()
	start := points.GetBalance("finuser")

	bus.Publish(bus.Event{Topic: "engine:upsert:bill", UserID: "finuser", Payload: entity("b1", "bill", map[string]interface{}{"name": "DEH", "paid": true})})
	if got := waitBalance("finuser", start+20); got != start+20 {
		t.Fatalf("expected +20 for paid bill, got %d (start %d)", got, start)
	}

	// Re-publishing the same bill as the rule saved it (flag persisted) must
	// NOT re-award — that's the client re-save path in production.
	saved := engine.GetEntitiesByUser("finuser")
	var reBill *engine.Entity
	for i := range saved {
		if saved[i].ID == "b1" {
			reBill = &saved[i]
		}
	}
	if reBill == nil {
		t.Fatalf("rule did not persist the bill entity")
	}
	if reBill.Payload["points_awarded"] != true {
		t.Fatalf("rule did not mark points_awarded")
	}
	bus.Publish(bus.Event{Topic: "engine:upsert:bill", UserID: "finuser", Payload: *reBill})
	if got := waitBalance("finuser", start+20); got != start+20 {
		t.Fatalf("expected dedup (still %d), got %d", start+20, got)
	}

	bus.Publish(bus.Event{Topic: "engine:upsert:bank_transaction", UserID: "finuser", Payload: entity("t1", "bank_transaction", map[string]interface{}{"type": "expense", "amount": 12.5})})
	if got := waitBalance("finuser", start+25); got != start+25 {
		t.Fatalf("expected +5 expense (%d total), got %d", start+25, got)
	}

	bus.Publish(bus.Event{Topic: "engine:upsert:bank_transaction", UserID: "finuser", Payload: entity("t2", "bank_transaction", map[string]interface{}{"type": "income", "amount": 600})})
	if got := waitBalance("finuser", start+35); got != start+35 {
		t.Fatalf("expected +10 income (%d total), got %d", start+35, got)
	}

	bus.Publish(bus.Event{Topic: "engine:upsert:budget_config", UserID: "finuser", Payload: entity("bc1", "budget_config", map[string]interface{}{"month": "2026-08", "income": 600})})
	if got := waitBalance("finuser", start+50); got != start+50 {
		t.Fatalf("expected +15 budget (%d total), got %d", start+50, got)
	}

	os.RemoveAll("./data")
}