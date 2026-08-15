package movies

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestMovieEndpoints(t *testing.T) {
	if err := InitDB(t.TempDir()); err != nil {
		t.Fatalf("InitDB: %v", err)
	}
	defer DB.Close()

	mux := http.NewServeMux()
	RegisterRoutes(mux)
	srv := httptest.NewServer(mux)
	defer srv.Close()

	get := func(path string, wantStatus int) []byte {
		resp, err := http.Get(srv.URL + path)
		if err != nil {
			t.Fatalf("GET %s: %v", path, err)
		}
		defer resp.Body.Close()
		if resp.StatusCode != wantStatus {
			t.Fatalf("GET %s: status %d, want %d", path, resp.StatusCode, wantStatus)
		}
		var buf bytes.Buffer
		buf.ReadFrom(resp.Body)
		return buf.Bytes()
	}

	post := func(path string, body string) {
		resp, err := http.Post(srv.URL+path, "application/json", bytes.NewBufferString(body))
		if err != nil {
			t.Fatalf("POST %s: %v", path, err)
		}
		defer resp.Body.Close()
		if resp.StatusCode != http.StatusOK {
			t.Fatalf("POST %s: status %d", path, resp.StatusCode)
		}
	}

	put := func(path string, body string, wantStatus int) {
		req, _ := http.NewRequest(http.MethodPut, srv.URL+path, bytes.NewBufferString(body))
		resp, err := http.DefaultClient.Do(req)
		if err != nil {
			t.Fatalf("PUT %s: %v", path, err)
		}
		defer resp.Body.Close()
		if resp.StatusCode != wantStatus {
			t.Fatalf("PUT %s: status %d, want %d", path, resp.StatusCode, wantStatus)
		}
	}

	// list: seeded + search + status filter
	var all []Movie
	if err := json.Unmarshal(get("/api/v1/movies", http.StatusOK), &all); err != nil || len(all) != 8 {
		t.Fatalf("list: got %d movies (err %v)", len(all), err)
	}
	var search []Movie
	if err := json.Unmarshal(get("/api/v1/movies?q=inter", http.StatusOK), &search); err != nil || len(search) != 1 || search[0].Title != "Interstellar" {
		t.Fatalf("search 'inter': %+v (err %v)", search, err)
	}
	var watched []Movie
	post("/api/v1/movies/reviews", `{"movie_id":"m3","rating":9.5,"comment":"masterpiece"}`)
	if err := json.Unmarshal(get("/api/v1/movies?status=WATCHED", http.StatusOK), &watched); err != nil || len(watched) != 1 {
		t.Fatalf("status filter: %+v (err %v)", watched, err)
	}

	// single movie carries the review rating
	var single Movie
	if err := json.Unmarshal(get("/api/v1/movies/m3", http.StatusOK), &single); err != nil || single.ImdbID != "tt0816692" || single.Rating != 9.5 {
		t.Fatalf("single: %+v (err %v)", single, err)
	}
	get("/api/v1/movies/does-not-exist", http.StatusNotFound)

	// watchlist: add once, add twice, list has exactly one entry
	post("/api/v1/movies/watchlist", `{"movie_id":"m3"}`)
	post("/api/v1/movies/watchlist", `{"movie_id":"m3"}`)
	var wl []map[string]any
	if err := json.Unmarshal(get("/api/v1/movies/watchlist", http.StatusOK), &wl); err != nil || len(wl) != 1 {
		t.Fatalf("watchlist: %+v (err %v)", wl, err)
	}

	// invalid rating rejected
	resp, err := http.Post(srv.URL+"/api/v1/movies/reviews", "application/json", bytes.NewBufferString(`{"movie_id":"m1","rating":99}`))
	if err == nil {
		resp.Body.Close()
		if resp.StatusCode != http.StatusBadRequest {
			t.Fatalf("bad rating: status %d, want 400", resp.StatusCode)
		}
	}

	// status update via PUT + validation
	put("/api/v1/movies/m1", `{"status":"WATCHED"}`, http.StatusOK)
	put("/api/v1/movies/m1", `{"status":"INVALID"}`, http.StatusBadRequest)
	put("/api/v1/movies/does-not-exist", `{"status":"WATCHED"}`, http.StatusNotFound)
}
