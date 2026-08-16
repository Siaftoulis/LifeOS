package books

import (
	"archive/zip"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func makeTestEpub(t *testing.T) string {
	t.Helper()
	dir := t.TempDir()
	path := filepath.Join(dir, "test.epub")
	f, err := os.Create(path)
	if err != nil {
		t.Fatal(err)
	}
	defer f.Close()
	zw := zip.NewWriter(f)
	files := map[string]string{
		"mimetype": "application/epub+zip",
		"ch1.xhtml": `<html><body><h1>Chapter One</h1><p>The hero walks into the forest at dusk.</p><script>bad()</script></body></html>`,
		"ch2.xhtml": `<html><body><h1>Chapter Two</h1><p>The dragon appears and speaks of the old wars.</p><style>.x{color:red}</style></body></html>`,
	}
	for name, content := range files {
		w, err := zw.Create(name)
		if err != nil {
			t.Fatal(err)
		}
		if _, err := w.Write([]byte(content)); err != nil {
			t.Fatal(err)
		}
	}
	if err := zw.Close(); err != nil {
		t.Fatal(err)
	}
	return path
}

func TestExtractEpubChapters(t *testing.T) {
	path := makeTestEpub(t)
	chs, err := extractEpubChapters(path)
	if err != nil {
		t.Fatalf("extract: %v", err)
	}
	if len(chs) != 2 {
		t.Fatalf("got %d chapters, want 2", len(chs))
	}
	// script/style content must be stripped
	for _, c := range chs {
		if strings.Contains(c.Text, "bad()") || strings.Contains(c.Text, "color:red") {
			t.Fatalf("script/style leaked into text: %q", c.Text)
		}
		if strings.Contains(c.Text, "<") {
			t.Fatalf("tags leaked into text: %q", c.Text)
		}
	}
}

func TestBestChapter(t *testing.T) {
	chs := []chapter{
		{Title: "forest", Text: "The hero walks through the forest meeting wolves."},
		{Title: "dragon", Text: "The dragon guards the mountain of gold."},
	}
	best := bestChapter(chs, "tell me about the dragon")
	if best == nil || best.Title != "dragon" {
		t.Fatalf("best chapter: got %+v, want dragon", best)
	}
	// no matching tokens -> still returns something (first best-score, ties
	// resolved by iteration order)
	best = bestChapter(chs, "zzz")
	if best == nil {
		t.Fatalf("expected a fallback chapter, got nil")
	}
}