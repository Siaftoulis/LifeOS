package music

import (
	"context"
	"testing"
	"time"
)

func TestSearchInnerTube(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	results, err := SearchInnerTube(ctx, "daft punk get lucky")
	if err != nil {
		t.Fatalf("SearchInnerTube failed: %v", err)
	}

	if len(results) == 0 {
		t.Fatalf("SearchInnerTube returned 0 results")
	}

	foundID := false
	for _, r := range results {
		if r.ID != "" && r.Title != "" {
			foundID = true
			break
		}
	}
	if !foundID {
		t.Errorf("Expected at least one result with valid ID and Title")
	}
}
