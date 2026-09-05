package music

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func newTestRouter(t *testing.T) *http.ServeMux {
	t.Helper()
	if err := InitDB(t.TempDir()); err != nil {
		t.Fatalf("InitDB: %v", err)
	}
	t.Cleanup(func() { DB.Close() })
	DB.Exec("INSERT INTO music_tracks (id, title, artist, album, file_path) VALUES (?, ?, ?, ?, ?)",
		"t1", "Nightcall", "Kavinsky", "OutRun", "test/nightcall.mp3")
	DB.Exec("INSERT INTO music_tracks (id, title, artist, album, file_path) VALUES (?, ?, ?, ?, ?)",
		"t2", "Resonance", "HOME", "Odyssey", "test/resonance.mp3")
	mux := http.NewServeMux()
	RegisterRoutes(mux)
	return mux
}

func TestTrackListSearchSingle(t *testing.T) {
	mux := newTestRouter(t)

	req := httptest.NewRequest("GET", "/api/v1/music/tracks?q=kavinsky", nil)
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("search: got %d, want 200", rec.Code)
	}
	var list []Track
	if err := json.Unmarshal(rec.Body.Bytes(), &list); err != nil {
		t.Fatalf("list decode: %v", err)
	}
	if len(list) != 1 || list[0].ID != "t1" {
		t.Fatalf("search: got %+v, want only t1", list)
	}

	req = httptest.NewRequest("GET", "/api/v1/music/tracks/t2", nil)
	rec = httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("get: got %d, want 200", rec.Code)
	}
	var track Track
	if err := json.Unmarshal(rec.Body.Bytes(), &track); err != nil {
		t.Fatalf("get decode: %v", err)
	}
	if track.Artist != "HOME" || track.FilePath == "" {
		t.Fatalf("get: got %+v, want HOME with file_path", track)
	}

	req = httptest.NewRequest("GET", "/api/v1/music/tracks/missing", nil)
	rec = httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusNotFound {
		t.Fatalf("get missing: got %d, want 404", rec.Code)
	}
}

func TestIsDirectYouTubeURL(t *testing.T) {
	valid := []string{
		"https://www.youtube.com/watch?v=dQw4w9WgXcQ",
		"https://youtube.com/watch?v=dQw4w9WgXcQ",
		"http://www.youtube.com/watch?v=dQw4w9WgXcQ",
		"https://youtu.be/dQw4w9WgXcQ",
		"https://m.youtube.com/watch?v=dQw4w9WgXcQ",
		"https://www.youtube.com/shorts/dQw4w9WgXcQ",
		"https://www.youtube.com/embed/dQw4w9WgXcQ",
		"https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s",
	}
	for _, u := range valid {
		if !isDirectYouTubeURL(u) {
			t.Errorf("expected isDirectYouTubeURL(%q) == true, got false", u)
		}
	}

	invalid := []string{
		"David Bowie - Starman",
		"https://example.com/watch?v=dQw4w9WgXcQ",
		"https://spotify.com/track/12345",
		"https://youtube.com",
		"https://youtu.be/",
		"https://www.youtube.com/playlist?list=PL1234567890",
		"",
	}
	for _, u := range invalid {
		if isDirectYouTubeURL(u) {
			t.Errorf("expected isDirectYouTubeURL(%q) == false, got true", u)
		}
	}
}
