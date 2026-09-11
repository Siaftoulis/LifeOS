package music

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestRecommendationsCaching(t *testing.T) {
	seed := "test_seed_123"
	cachedTracks := []RecommendedTrack{
		{
			ID:        "track1",
			Title:     "Recommendation 1",
			Artist:    "Artist A",
			Duration:  210,
			StreamURL: "/api/v1/music/ytstream/stream.m4a?id=track1",
		},
		{
			ID:        "track2",
			Title:     "Recommendation 2",
			Artist:    "Artist B",
			Duration:  180,
			StreamURL: "/api/v1/music/ytstream/stream.m4a?id=track2",
		},
	}

	recMu.Lock()
	recCache[seed] = recCacheEntry{
		tracks:    cachedTracks,
		expiresAt: time.Now().Add(10 * time.Minute),
	}
	recMu.Unlock()

	ctx := context.Background()
	results, err := FetchYouTubeMusicRadio(ctx, seed, 10)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(results) != 2 {
		t.Fatalf("expected 2 cached results, got %d", len(results))
	}
	if results[0].ID != "track1" || results[1].ID != "track2" {
		t.Fatalf("unexpected cached results data: %+v", results)
	}
}

func TestHandleRecommendationsEndpoint(t *testing.T) {
	// Seed cache so handler can return fast
	seed := "seeded_vid_99"
	recMu.Lock()
	recCache[seed] = recCacheEntry{
		tracks: []RecommendedTrack{
			{
				ID:        "rec_song",
				Title:     "Algorithmic Pick",
				Artist:    "YTM Engine",
				Duration:  200,
				StreamURL: "/api/v1/music/ytstream/stream.m4a?id=rec_song",
			},
		},
		expiresAt: time.Now().Add(10 * time.Minute),
	}
	recMu.Unlock()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/music/recommendations?id="+seed, nil)
	w := httptest.NewRecorder()

	HandleRecommendations(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200 OK, got %d: %s", w.Code, w.Body.String())
	}

	body := w.Body.String()
	if !stringsContains(body, "rec_song") || !stringsContains(body, "Algorithmic Pick") {
		t.Fatalf("expected response to contain rec_song, got: %s", body)
	}
}

func stringsContains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || len(substr) == 0 || (len(s) > 0 && len(substr) > 0 && indexOf(s, substr) >= 0))
}

func indexOf(s, substr string) int {
	for i := 0; i+len(substr) <= len(s); i++ {
		if s[i:i+len(substr)] == substr {
			return i
		}
	}
	return -1
}

func TestSmartVibeScoringAndAffinity(t *testing.T) {
	profile := UserAffinityProfile{
		ArtistScores: map[string]float64{
			"adele": 1.5,
			"bad artist": -1.5,
		},
		GenreScores: map[string]float64{
			"soul": 2.0,
		},
	}

	goodTrack := RecommendedTrack{
		ID:     "t1",
		Title:  "Someone Like You",
		Artist: "Adele",
	}

	serendipityTrack := RecommendedTrack{
		ID:     "t2",
		Title:  "Stay With Me",
		Artist: "Sam Smith",
	}

	skippedTrack := RecommendedTrack{
		ID:     "t3",
		Title:  "Random Track",
		Artist: "Bad Artist",
	}

	scoreGood := ScoreRecommendation(goodTrack, "Adele", "Soul", profile, false)
	scoreSerendipity := ScoreRecommendation(serendipityTrack, "Adele", "Soul", profile, true)
	scoreSkipped := ScoreRecommendation(skippedTrack, "Adele", "Soul", profile, false)

	if scoreGood <= scoreSkipped {
		t.Fatalf("expected good track score (%f) to be higher than skipped track score (%f)", scoreGood, scoreSkipped)
	}

	if scoreSerendipity <= 0 {
		t.Fatalf("expected positive score for serendipity track, got %f", scoreSerendipity)
	}
}
