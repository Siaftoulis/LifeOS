package zen

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func setupDB(t *testing.T) {
	t.Helper()
	if err := InitDB(t.TempDir()); err != nil {
		t.Fatalf("InitDB: %v", err)
	}
	t.Cleanup(func() { DB.Close() })
}

func TestSyncPushPull(t *testing.T) {
	setupDB(t)
	mux := http.NewServeMux()
	RegisterRoutes(mux)

	post := func(body any) map[string]any {
		raw, _ := json.Marshal(body)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/zen/sync", bytes.NewReader(raw))
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		if rec.Code != http.StatusOK {
			t.Fatalf("status %d: %s", rec.Code, rec.Body.String())
		}
		var out map[string]any
		json.Unmarshal(rec.Body.Bytes(), &out)
		return out
	}

	// Push one node+doc.
	out := post(syncRequest{
		PushNodes: []nodePush{{
			ID: "n1", Name: "note.md", Path: "note.md", UpdatedAt: 1000, CreatedAt: 1000,
		}},
		PushDocuments: []docPush{{ID: "d1", NodeID: "n1", Text: "hello", UpdatedAt: 1000}},
		Since:         0,
	})
	if len(out["nodes"].([]any)) != 1 || len(out["documents"].([]any)) != 1 {
		t.Fatalf("expected 1 node + 1 doc in pull, got %v", out)
	}

	// Pull since=1000 → nothing new.
	out = post(syncRequest{Since: 1000})
	if len(out["nodes"].([]any)) != 0 || len(out["documents"].([]any)) != 0 {
		t.Fatalf("since=1000 should pull nothing, got %v", out)
	}

	// Older push is ignored (LWW), newer push wins.
	post(syncRequest{PushNodes: []nodePush{{
		ID: "n1", Name: "note.md", Path: "note.md", UpdatedAt: 500, CreatedAt: 1000,
	}}})
	out = post(syncRequest{PushNodes: []nodePush{{
		ID: "n1", Name: "note.md", Path: "note.md", UpdatedAt: 2000, CreatedAt: 1000,
	}}, Since: 0})
	nodes := out["nodes"].([]any)
	if len(nodes) != 1 || int((nodes[0].(map[string]any)["updated_at"]).(float64)) != 2000 {
		t.Fatalf("LWW failed: %v", out)
	}

	// Delete with tombstone.
	out = post(syncRequest{DeletePaths: []string{"note.md"}, Since: 0})
	tombs := out["deleted_paths"].([]any)
	if len(tombs) != 1 || tombs[0] != "note.md" {
		t.Fatalf("expected tombstone note.md, got %v", out)
	}
	if len(out["nodes"].([]any)) != 0 {
		t.Fatalf("node should be deleted, got %v", out)
	}
}

func TestDatabaseFile(t *testing.T) {
	setupDB(t)
	var n int
	if err := DB.QueryRow(`SELECT COUNT(*) FROM zen_nodes`).Scan(&n); err != nil || n != 0 {
		t.Fatalf("empty table expected: %v n=%d", err, n)
	}
}
