package music

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func setupTestMusicServer(t *testing.T) *http.ServeMux {
	t.Helper()
	setupTestDB(t)

	// Insert test tracks
	now := time.Now().UnixMilli()
	_, err := DB.Exec(`INSERT INTO music_tracks 
		(id, title, artist, album, genre, file_path, duration, thumbnail, thumbnail_url, added_at, play_count)
		VALUES 
		('tr1', 'Song One', 'Artist A', 'Album 1', 'Synthwave', 'media/music/song1.mp3', 180, 'https://example.com/thumb1.jpg', 'https://example.com/thumb1.jpg', ?, 10),
		('tr2', 'Song Two', 'Artist A', 'Album 1', 'Synthwave', 'media/music/song2.mp3', 200, 'https://example.com/thumb2.jpg', 'https://example.com/thumb2.jpg', ?, 5),
		('tr3', 'Song Three', 'Artist B', 'Album 2', 'Ambient', 'media/music/song3.mp3', 240, 'https://example.com/thumb3.jpg', 'https://example.com/thumb3.jpg', ?, 1)
	`, now, now, now)
	if err != nil {
		t.Fatalf("insert test tracks failed: %v", err)
	}

	// Insert liked song
	_, err = DB.Exec("INSERT INTO liked_songs (id, liked_at) VALUES ('tr1', ?)", now)
	if err != nil {
		t.Fatalf("insert liked_songs failed: %v", err)
	}

	// Insert playlist and playlist track
	_, err = DB.Exec("INSERT INTO playlists (id, name, created_at, updated_at) VALUES ('pl1', 'Test Playlist', ?, ?)", now, now)
	if err != nil {
		t.Fatalf("insert playlist failed: %v", err)
	}
	_, err = DB.Exec("INSERT INTO playlist_tracks (id, playlist_id, track_id, position, added_at) VALUES ('pl1-tr1', 'pl1', 'tr1', 0, ?)", now)
	if err != nil {
		t.Fatalf("insert playlist_track failed: %v", err)
	}

	// Insert listening history
	_, err = DB.Exec("INSERT INTO listening_history (id, track_id, played_at, position_ms, duration_ms, source) VALUES ('lh1', 'tr1', ?, 180000, 180000, 'library')", now)
	if err != nil {
		t.Fatalf("insert listening_history failed: %v", err)
	}

	mux := http.NewServeMux()
	RegisterRoutes(mux)
	return mux
}

func TestLikedSongsHandlerMapping(t *testing.T) {
	mux := setupTestMusicServer(t)

	req := httptest.NewRequest("GET", "/api/v1/music/liked", nil)
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("GET /liked: got %d, want 200", rec.Code)
	}

	var tracks []Track
	if err := json.Unmarshal(rec.Body.Bytes(), &tracks); err != nil {
		t.Fatalf("decode liked tracks: %v", err)
	}

	if len(tracks) != 1 {
		t.Fatalf("expected 1 liked track, got %d", len(tracks))
	}

	tr := tracks[0]
	if tr.ID != "tr1" {
		t.Fatalf("expected track ID tr1, got %q", tr.ID)
	}
	if tr.FilePath != "media/music/song1.mp3" {
		t.Fatalf("expected FilePath 'media/music/song1.mp3', got %q", tr.FilePath)
	}
	if tr.Thumbnail != "https://example.com/thumb1.jpg" {
		t.Fatalf("expected Thumbnail 'https://example.com/thumb1.jpg', got %q", tr.Thumbnail)
	}
	if tr.ThumbnailURL != "https://example.com/thumb1.jpg" {
		t.Fatalf("expected ThumbnailURL 'https://example.com/thumb1.jpg', got %q", tr.ThumbnailURL)
	}
}

func TestPlaylistTracksHandlerMapping(t *testing.T) {
	mux := setupTestMusicServer(t)

	req := httptest.NewRequest("GET", "/api/v1/music/playlists/pl1/tracks", nil)
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("GET playlist tracks: got %d, want 200", rec.Code)
	}

	var tracks []PlaylistTrack
	if err := json.Unmarshal(rec.Body.Bytes(), &tracks); err != nil {
		t.Fatalf("decode playlist tracks: %v", err)
	}

	if len(tracks) != 1 {
		t.Fatalf("expected 1 track in playlist pl1, got %d", len(tracks))
	}

	tr := tracks[0].Track
	if tr.FilePath != "media/music/song1.mp3" {
		t.Fatalf("expected FilePath 'media/music/song1.mp3', got %q", tr.FilePath)
	}
	if tr.Thumbnail != "https://example.com/thumb1.jpg" {
		t.Fatalf("expected Thumbnail 'https://example.com/thumb1.jpg', got %q", tr.Thumbnail)
	}
}

func TestSmartPlaylistHandlerMapping(t *testing.T) {
	mux := setupTestMusicServer(t)

	// Test Daily Mix
	req := httptest.NewRequest("GET", "/api/v1/music/smart/daily-mix?seed=Artist+A", nil)
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("GET daily-mix: got %d, want 200", rec.Code)
	}

	var tracks []Track
	if err := json.Unmarshal(rec.Body.Bytes(), &tracks); err != nil {
		t.Fatalf("decode daily-mix: %v", err)
	}

	if len(tracks) < 2 {
		t.Fatalf("expected at least 2 tracks in daily-mix for Artist A, got %d", len(tracks))
	}

	for _, tr := range tracks {
		if tr.FilePath == "" {
			t.Fatalf("track %s returned with empty FilePath", tr.ID)
		}
		if tr.Thumbnail == "" {
			t.Fatalf("track %s returned with empty Thumbnail", tr.ID)
		}
	}
}

func TestListeningHistoryThumbnail(t *testing.T) {
	mux := setupTestMusicServer(t)

	req := httptest.NewRequest("GET", "/api/v1/music/history", nil)
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("GET /history: got %d, want 200", rec.Code)
	}

	var history []HistoryItem
	if err := json.Unmarshal(rec.Body.Bytes(), &history); err != nil {
		t.Fatalf("decode history: %v", err)
	}

	if len(history) != 1 {
		t.Fatalf("expected 1 history item, got %d", len(history))
	}

	if history[0].ThumbnailURL != "https://example.com/thumb1.jpg" {
		t.Fatalf("expected ThumbnailURL 'https://example.com/thumb1.jpg', got %q", history[0].ThumbnailURL)
	}
}

func TestThumbnailBackwardCompatibility(t *testing.T) {
	setupTestDB(t)

	// Simulate legacy track with only thumbnail_url
	_, err := DB.Exec(`INSERT INTO music_tracks (id, title, artist, album, file_path, thumbnail, thumbnail_url)
		VALUES ('legacy_url', 'Legacy URL Track', 'Artist', 'Album', 'media/legacy1.mp3', '', 'https://example.com/url_only.jpg')`)
	if err != nil {
		t.Fatalf("insert legacy_url failed: %v", err)
	}

	// Simulate track with only thumbnail
	_, err = DB.Exec(`INSERT INTO music_tracks (id, title, artist, album, file_path, thumbnail, thumbnail_url)
		VALUES ('legacy_thumb', 'Legacy Thumb Track', 'Artist', 'Album', 'media/legacy2.mp3', 'https://example.com/thumb_only.jpg', '')`)
	if err != nil {
		t.Fatalf("insert legacy_thumb failed: %v", err)
	}

	// Re-run createTables to trigger the migration/sync
	if err := createTables(); err != nil {
		t.Fatalf("createTables migration failed: %v", err)
	}

	var thumb1, url1 string
	err = DB.QueryRow("SELECT thumbnail, thumbnail_url FROM music_tracks WHERE id = 'legacy_url'").Scan(&thumb1, &url1)
	if err != nil {
		t.Fatalf("query legacy_url: %v", err)
	}
	if thumb1 != "https://example.com/url_only.jpg" || url1 != "https://example.com/url_only.jpg" {
		t.Fatalf("sync failed for legacy_url: thumb=%q, url=%q", thumb1, url1)
	}

	var thumb2, url2 string
	err = DB.QueryRow("SELECT thumbnail, thumbnail_url FROM music_tracks WHERE id = 'legacy_thumb'").Scan(&thumb2, &url2)
	if err != nil {
		t.Fatalf("query legacy_thumb: %v", err)
	}
	if thumb2 != "https://example.com/thumb_only.jpg" || url2 != "https://example.com/thumb_only.jpg" {
		t.Fatalf("sync failed for legacy_thumb: thumb=%q, url=%q", thumb2, url2)
	}
}
