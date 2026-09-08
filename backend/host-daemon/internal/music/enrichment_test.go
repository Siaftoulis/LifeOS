package music

import (
	"context"
	"testing"
	"time"
)

func TestCleanTitle(t *testing.T) {
	cases := []struct {
		input       string
		wantTitle   string
		wantFeature string
	}{
		{
			input:       "Daft Punk - Get Lucky (Official Audio)",
			wantTitle:   "Daft Punk - Get Lucky",
			wantFeature: "",
		},
		{
			input:       "Get Lucky feat. Pharrell Williams",
			wantTitle:   "Get Lucky",
			wantFeature: "Pharrell Williams",
		},
		{
			input:       "Track Title [4K] (Official Music Video)",
			wantTitle:   "Track Title",
			wantFeature: "",
		},
	}

	for _, c := range cases {
		title, feat := CleanTitle(c.input)
		if title != c.wantTitle {
			t.Errorf("CleanTitle(%q) title = %q, want %q", c.input, title, c.wantTitle)
		}
		if feat != c.wantFeature {
			t.Errorf("CleanTitle(%q) feat = %q, want %q", c.input, feat, c.wantFeature)
		}
	}
}

func TestEnrichMetadata(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 8*time.Second)
	defer cancel()

	meta := EnrichMetadata(ctx, "Get Lucky", "Daft Punk")
	if meta.Title == "" {
		t.Errorf("Expected non-empty enriched title")
	}
	if meta.CoverArtURL == "" {
		t.Errorf("Expected non-empty high-resolution cover art URL")
	}
}
