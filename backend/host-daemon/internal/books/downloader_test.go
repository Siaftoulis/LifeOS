package books

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestEnqueueDownload(t *testing.T) {
	if err := InitDB(t.TempDir()); err != nil {
		t.Fatalf("InitDB: %v", err)
	}
	t.Cleanup(func() { DB.Close() })
	booksDir = t.TempDir()

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Length", "11")
		w.Write([]byte("hello world"))
	}))
	defer srv.Close()

	job, err := EnqueueDownload(DownloadJob{URL: srv.URL + "/book.epub", Title: "Test Book", Author: "Me", Format: "epub"})
	if err != nil {
		t.Fatalf("enqueue: %v", err)
	}
	if job.Status != "PENDING" {
		t.Fatalf("initial status: got %q, want PENDING", job.Status)
	}

	// poll for completion
	var done *DownloadJob
	for i := 0; i < 50; i++ {
		jobs, err := ListDownloads()
		if err != nil {
			t.Fatalf("list: %v", err)
		}
		for j := range jobs {
			if jobs[j].ID == job.ID {
				done = &jobs[j]
			}
		}
		if done != nil && done.Status == "DONE" {
			break
		}
		time.Sleep(20 * time.Millisecond)
	}
	if done == nil || done.Status != "DONE" {
		t.Fatalf("job never finished: %+v", done)
	}
	if done.ProgressBytes != 11 {
		t.Fatalf("progress: got %d, want 11", done.ProgressBytes)
	}
	if !strings.HasSuffix(done.FilePath, "book.epub") {
		t.Fatalf("file path: got %q", done.FilePath)
	}

	// book imported
	var count int
	DB.QueryRow("SELECT COUNT(*) FROM books WHERE title = 'Test Book'").Scan(&count)
	if count != 1 {
		t.Fatalf("imported books: got %d, want 1", count)
	}
}

func TestDownloadBadStatus(t *testing.T) {
	if err := InitDB(t.TempDir()); err != nil {
		t.Fatalf("InitDB: %v", err)
	}
	t.Cleanup(func() { DB.Close() })
	booksDir = t.TempDir()

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		http.Error(w, "nope", http.StatusNotFound)
	}))
	defer srv.Close()

	job, err := EnqueueDownload(DownloadJob{URL: srv.URL + "/x.epub", Title: "Fail Book"})
	if err != nil {
		t.Fatalf("enqueue: %v", err)
	}
	var done *DownloadJob
	for i := 0; i < 50; i++ {
		jobs, _ := ListDownloads()
		for j := range jobs {
			if jobs[j].ID == job.ID {
				done = &jobs[j]
			}
		}
		if done != nil && done.Status == "FAILED" {
			break
		}
		time.Sleep(20 * time.Millisecond)
	}
	if done == nil || done.Status != "FAILED" {
		t.Fatalf("job should fail: %+v", done)
	}
	if done.Error == "" {
		t.Fatalf("expected error message, got empty")
	}
}