package sources

import (
	"context"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
)

const fakeAnnasPage = `<!DOCTYPE html><html><body>
<div class="search-results">
<!--
<div class="book-item">
<a href="/md5/aaaabbbbccccddddeeeeffff00001111"><h2>The Pragmatic Programmer</h2></a>
<p class="book-author">Andrew Hunt</p>
<p class="book-meta">epub, 2.3 MB</p>
</div>
-->
<div class="book-item">
<a href="/md5/22223333444455556666777788889999"><h2>Clean Code</h2></a>
<p class="book-author">Robert C. Martin</p>
<p class="book-meta">pdf, 5.1 MB</p>
</div>
</div></body></html>`

func TestSearchAnnasScraper(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte(fakeAnnasPage))
	}))
	defer srv.Close()

	old := os.Getenv("ANNAS_ARCHIVE_BASE")
	os.Setenv("ANNAS_ARCHIVE_BASE", srv.URL)
	defer os.Setenv("ANNAS_ARCHIVE_BASE", old)

	results := searchAnnas(context.Background(), "pragmatic")
	if len(results) != 2 {
		t.Fatalf("got %d results, want 2: %+v", len(results), results)
	}
	if results[0].Title != "The Pragmatic Programmer" {
		t.Fatalf("title: got %q", results[0].Title)
	}
	if results[0].Author != "Andrew Hunt" {
		t.Fatalf("author: got %q", results[0].Author)
	}
	if results[0].Size != "2.3 MB" {
		t.Fatalf("size: got %q", results[0].Size)
	}
	if results[0].DownloadURL != srv.URL+"/md5/aaaabbbbccccddddeeeeffff00001111" {
		t.Fatalf("download url: got %q", results[0].DownloadURL)
	}
	if results[0].Source != "annas" || results[0].Confidence != 80 {
		t.Fatalf("source/confidence: got %q/%d", results[0].Source, results[0].Confidence)
	}
}