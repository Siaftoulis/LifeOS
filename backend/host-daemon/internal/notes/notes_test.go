package notes

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
)

func newTestRouter(t *testing.T) (*http.ServeMux, string) {
	t.Helper()
	vault := t.TempDir()
	write := func(rel, content string) {
		t.Helper()
		abs := filepath.Join(vault, filepath.FromSlash(rel))
		if err := os.MkdirAll(filepath.Dir(abs), 0755); err != nil {
			t.Fatalf("mkdir: %v", err)
		}
		if err := os.WriteFile(abs, []byte(content), 0644); err != nil {
			t.Fatalf("write: %v", err)
		}
	}
	write("01 - Tiles/Home.md", "# Home\nWelcome to LifeOS.")
	write("secret.md", "# Secret\nShould not appear.\n")
	write("02 - LifeOS/Notes/Plan.md", "---\nid: x\n---\nPlan text.\n")
	write(".obsidian/app.json", "{}")
	write("assets/image.png", "binary")

	mux := http.NewServeMux()
	RegisterRoutes(mux, vault)
	return mux, vault
}

func TestNoteListSearch(t *testing.T) {
	mux, _ := newTestRouter(t)

	req := httptest.NewRequest("GET", "/api/v1/notes", nil)
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("list: got %d, want 200", rec.Code)
	}
	var notes []Note
	if err := json.Unmarshal(rec.Body.Bytes(), &notes); err != nil {
		t.Fatalf("decode: %v", err)
	}
	if len(notes) != 3 {
		t.Fatalf("list: got %d notes, want 3 (hidden dirs/non-md excluded): %+v", len(notes), notes)
	}

	req = httptest.NewRequest("GET", "/api/v1/notes?q=plan", nil)
	rec = httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	json.Unmarshal(rec.Body.Bytes(), &notes)
	if len(notes) != 1 || notes[0].ID != "02 - LifeOS/Notes/Plan" {
		t.Fatalf("search: got %+v, want Plan only", notes)
	}
}

func TestNoteGet(t *testing.T) {
	mux, _ := newTestRouter(t)

	req := httptest.NewRequest("GET", "/api/v1/notes/01%20-%20Tiles/Home", nil)
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("get: got %d, want 200", rec.Code)
	}
	var n Note
	if err := json.Unmarshal(rec.Body.Bytes(), &n); err != nil {
		t.Fatalf("decode: %v", err)
	}
	if n.Title != "Home" || n.Snippet != "Welcome to LifeOS." {
		t.Fatalf("get: got %+v, want Home with snippet", n)
	}

	req = httptest.NewRequest("GET", "/api/v1/notes/02%20-%20LifeOS/Notes/Plan", nil)
	rec = httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	json.Unmarshal(rec.Body.Bytes(), &n)
	if n.Snippet != "Plan text." {
		t.Fatalf("frontmatter snippet: got %q, want 'Plan text.'", n.Snippet)
	}

	for _, bad := range []string{"missing", "..%2F..%2Fetc", "%2Fetc%2Fpasswd"} {
		req = httptest.NewRequest("GET", "/api/v1/notes/"+bad, nil)
		rec = httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		if rec.Code != http.StatusNotFound {
			t.Fatalf("get %q: got %d, want 404", bad, rec.Code)
		}
	}
}
