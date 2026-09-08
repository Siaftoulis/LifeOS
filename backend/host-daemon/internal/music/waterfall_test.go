package music

import (
	"context"
	"testing"
	"time"
)

func TestResolveWaterfall_FastMode(t *testing.T) {
	ctx := context.Background()
	meta := EnrichedMetadata{
		Artist: "Artist",
		Title:  "Title",
	}
	rawURL := "https://www.youtube.com/watch?v=123"

	src := ResolveWaterfall(ctx, meta, rawURL, "fast")
	if src.Tier != "tier3_youtube" {
		t.Errorf("expected tier3_youtube for fast mode, got %s", src.Tier)
	}
	if src.ResolvedURL != rawURL {
		t.Errorf("expected %s, got %s", rawURL, src.ResolvedURL)
	}
}

func TestResolveWaterfall_EmptyQuery(t *testing.T) {
	ctx := context.Background()
	meta := EnrichedMetadata{}
	rawURL := "https://www.youtube.com/watch?v=123"

	src := ResolveWaterfall(ctx, meta, rawURL, "best")
	if src.Tier != "tier3_youtube" {
		t.Errorf("expected tier3_youtube for empty query, got %s", src.Tier)
	}
}

func TestResolveWaterfall_SoundCloudQuery(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	meta := EnrichedMetadata{
		Artist: "Rare Artist",
		Title:  "Unreleased Track",
	}
	rawURL := "https://www.youtube.com/watch?v=xyz"

	src := ResolveWaterfall(ctx, meta, rawURL, "best")
	// Since Soulseek & Archive are unavailable for this mock query, it cascades to SoundCloud or YouTube
	if src.Tier != "tier2_soundcloud_hq" && src.Tier != "tier3_youtube" {
		t.Errorf("expected tier2_soundcloud_hq or tier3_youtube, got %s", src.Tier)
	}
}
