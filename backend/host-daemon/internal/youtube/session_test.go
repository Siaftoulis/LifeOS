package youtube

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
	"time"
)

// TestSessionCharge exercises the money path: start -> charge -> ledger,
// with the block rounding (every started 30 min = -10 PTS).
func TestSessionCharge(t *testing.T) {
	dir := t.TempDir()
	if err := InitDB(dir); err != nil {
		t.Fatal(err)
	}
	defer cleanupPointsFiles()

	user := "testuser"
	started := time.Now().Add(-45 * time.Minute)
	if err := insertSession(user, started); err != nil {
		t.Fatal(err)
	}
	if _, ok := getSession(user); !ok {
		t.Fatal("session should be active")
	}

	res := chargeAndClose(user, started)
	if res.PointsDeducted != 20 { // 45 min = 2 started blocks
		t.Fatalf("45min session: deducted %d, want 20", res.PointsDeducted)
	}
	if res.NewBalance != -20 {
		t.Fatalf("new balance %d, want -20", res.NewBalance)
	}
	if _, ok := getSession(user); ok {
		t.Fatal("session should be closed after stop")
	}

	// Rounding table: 29 min -> 10, 31 min -> 20, 60 min -> 20, 90 min -> 30.
	for dur, want := range map[time.Duration]int{
		-29 * time.Minute: 10,
		-31 * time.Minute: 20,
		-60 * time.Minute: 20,
		-90 * time.Minute: 30,
	} {
		if got := estCost(time.Now().Add(dur)); got != want {
			t.Fatalf("estCost(%v) = %d, want %d", dur, got, want)
		}
	}

	// Ledger must contain the charge.
	found := false
	for _, e := range ledgerEntries() {
		if e.UserID == user && e.Event == "YouTube Session 45m" && e.Points == -20 {
			found = true
		}
	}
	if !found {
		t.Fatal("charge not found in ledger")
	}
}

type ledgerRow struct {
	UserID string `json:"user_id"`
	Event  string `json:"event"`
	Points int    `json:"points"`
}

// ledgerEntries reads the ledger file the points package wrote.
func ledgerEntries() []ledgerRow {
	data, _ := os.ReadFile(filepath.Join(".", "data", "ledger.json"))
	var entries []ledgerRow
	_ = json.Unmarshal(data, &entries)
	return entries
}

func cleanupPointsFiles() {
	if DB != nil {
		DB.Close()
	}
	os.Remove(filepath.Join(".", "data", "points.json"))
	os.Remove(filepath.Join(".", "data", "ledger.json"))
}