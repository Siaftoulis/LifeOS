package books

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func newTestRouter(t *testing.T) *http.ServeMux {
	t.Helper()
	if err := InitDB(t.TempDir()); err != nil {
		t.Fatalf("InitDB: %v", err)
	}
	mux := http.NewServeMux()
	RegisterRoutes(mux)
	return mux
}

func TestBookListSearchSingleStatus(t *testing.T) {
	mux := newTestRouter(t)
	t.Cleanup(func() { DB.Close() })

	req := httptest.NewRequest("GET", "/api/v1/books?q=clean", nil)
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("list: got %d, want 200", rec.Code)
	}
	var list []Book
	if err := json.Unmarshal(rec.Body.Bytes(), &list); err != nil {
		t.Fatalf("list decode: %v", err)
	}
	if len(list) != 1 || list[0].ID != "book-2" {
		t.Fatalf("search: got %+v, want only book-2", list)
	}

	req = httptest.NewRequest("GET", "/api/v1/books/book-1", nil)
	rec = httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("get: got %d, want 200", rec.Code)
	}
	var b Book
	if err := json.Unmarshal(rec.Body.Bytes(), &b); err != nil {
		t.Fatalf("get decode: %v", err)
	}
	if b.Status != "NOT_STARTED" {
		t.Fatalf("default status: got %q, want NOT_STARTED", b.Status)
	}

	req = httptest.NewRequest("GET", "/api/v1/books/missing", nil)
	rec = httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusNotFound {
		t.Fatalf("get missing: got %d, want 404", rec.Code)
	}

	put := strings.NewReader(`{"status":"READING"}`)
	req = httptest.NewRequest("PUT", "/api/v1/books/book-1", put)
	rec = httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("put: got %d, want 200 (body %s)", rec.Code, rec.Body.String())
	}

	req = httptest.NewRequest("GET", "/api/v1/books/book-1", nil)
	rec = httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	json.Unmarshal(rec.Body.Bytes(), &b)
	if b.Status != "READING" {
		t.Fatalf("status after put: got %q, want READING", b.Status)
	}

	req = httptest.NewRequest("PUT", "/api/v1/books/book-1", strings.NewReader(`{"status":"BOGUS"}`))
	rec = httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("put bad status: got %d, want 400", rec.Code)
	}
}

func TestBookUpsert(t *testing.T) {
	mux := newTestRouter(t)
	t.Cleanup(func() { DB.Close() })

	post := strings.NewReader(`{"id":"new-1","title":"Sync Test Book","author":"Me","current_page":10,"total_pages":200,"file_path":"","status":"READING"}`)
	req := httptest.NewRequest("POST", "/api/v1/books", post)
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("post: got %d, want 200 (body %s)", rec.Code, rec.Body.String())
	}

	req = httptest.NewRequest("GET", "/api/v1/books?q=sync+test", nil)
	rec = httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	var list []Book
	if err := json.Unmarshal(rec.Body.Bytes(), &list); err != nil {
		t.Fatalf("decode: %v", err)
	}
	if len(list) != 1 || list[0].ID != "new-1" || list[0].Status != "READING" {
		t.Fatalf("after post: got %+v, want new-1 READING", list)
	}

	// Upsert same id again: still one row, fields updated.
	post = strings.NewReader(`{"id":"new-1","title":"Sync Test Book v2","author":"Me","current_page":50,"total_pages":200,"file_path":"","status":"FINISHED"}`)
	req = httptest.NewRequest("POST", "/api/v1/books", post)
	rec = httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("re-post: got %d, want 200", rec.Code)
	}

	req = httptest.NewRequest("GET", "/api/v1/books/new-1", nil)
	rec = httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	var b Book
	if err := json.Unmarshal(rec.Body.Bytes(), &b); err != nil {
		t.Fatalf("decode: %v", err)
	}
	if b.Title != "Sync Test Book v2" || b.CurrentPage != 50 || b.Status != "FINISHED" {
		t.Fatalf("after upsert: got %+v", b)
	}

	var count int
	DB.QueryRow("SELECT COUNT(*) FROM books WHERE id = 'new-1'").Scan(&count)
	if count != 1 {
		t.Fatalf("upsert created %d rows, want 1", count)
	}

	// Bad status rejected.
	post = strings.NewReader(`{"id":"new-2","title":"X","status":"BOGUS"}`)
	req = httptest.NewRequest("POST", "/api/v1/books", post)
	rec = httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("bad status: got %d, want 400", rec.Code)
	}
}
