package music

import (
	"context"
	"testing"
	"time"
)

func setupTestDB(t *testing.T) {
	t.Helper()
	dir := t.TempDir()
	if err := InitDB(dir); err != nil {
		t.Fatalf("InitDB failed: %v", err)
	}
	t.Cleanup(func() {
		StopQueueWorker()
		if DB != nil {
			DB.Close()
		}
	})
}

func TestDownloadQueueLifecycleSuccess(t *testing.T) {
	setupTestDB(t)

	oldRunner := commandRunner
	defer func() { commandRunner = oldRunner }()
	commandRunner = mockCommandRunner("success-download")

	queueID, err := EnqueueDownload("vid1", "https://i.ytimg.com/vi/vid1/hqdefault.jpg", 10, "testuser")
	if err != nil {
		t.Fatalf("EnqueueDownload failed: %v", err)
	}

	// Verify initially pending
	var status string
	err = DB.QueryRow("SELECT status FROM download_queue WHERE id = ?", queueID).Scan(&status)
	if err != nil || status != "pending" {
		t.Fatalf("expected pending status, got %q (err: %v)", status, err)
	}

	// Process queue item synchronously
	worked, err := processNextDownload(context.Background())
	if err != nil {
		t.Fatalf("processNextDownload returned error: %v", err)
	}
	if !worked {
		t.Fatalf("expected work to be processed")
	}

	// Verify completed status and destination path
	var destPath string
	err = DB.QueryRow("SELECT status, destination_path FROM download_queue WHERE id = ?", queueID).Scan(&status, &destPath)
	if err != nil {
		t.Fatalf("query download_queue failed: %v", err)
	}
	if status != "completed" {
		t.Fatalf("expected status 'completed', got %q", status)
	}
	if destPath != "test/saved.mp3" {
		t.Fatalf("expected destPath 'test/saved.mp3', got %q", destPath)
	}

	// Verify track inserted into music_tracks with canonical thumbnails
	var track Track
	var thumbURL string
	err = DB.QueryRow("SELECT id, title, artist, album, file_path, duration, thumbnail, thumbnail_url FROM music_tracks WHERE id = ?", "vid1").
		Scan(&track.ID, &track.Title, &track.Artist, &track.Album, &track.FilePath, &track.Duration, &track.Thumbnail, &thumbURL)
	if err != nil {
		t.Fatalf("track was not inserted into music_tracks: %v", err)
	}
	if track.Title != "Song Title" || track.Artist != "Artist Name" {
		t.Fatalf("track metadata mismatch: %+v", track)
	}
	if track.Thumbnail == "" || track.Thumbnail != thumbURL {
		t.Fatalf("thumbnail mismatch: thumb=%q, thumbURL=%q", track.Thumbnail, thumbURL)
	}
}

func TestDownloadQueueFailure(t *testing.T) {
	setupTestDB(t)

	oldRunner := commandRunner
	defer func() { commandRunner = oldRunner }()
	commandRunner = mockCommandRunner("fail")

	queueID, err := EnqueueDownload("vid_err", "", 0, "")
	if err != nil {
		t.Fatalf("EnqueueDownload failed: %v", err)
	}

	worked, err := processNextDownload(context.Background())
	if err == nil {
		t.Fatalf("expected processNextDownload to report error on failure")
	}
	if !worked {
		t.Fatalf("expected work to be attempted")
	}

	var status, errMsg string
	err = DB.QueryRow("SELECT status, error_message FROM download_queue WHERE id = ?", queueID).Scan(&status, &errMsg)
	if err != nil {
		t.Fatalf("query download_queue failed: %v", err)
	}
	if status != "failed" {
		t.Fatalf("expected status 'failed', got %q", status)
	}
	if errMsg == "" {
		t.Fatalf("expected error_message to be populated on failure")
	}
}

func TestDownloadQueueCancellationBeforeExecution(t *testing.T) {
	setupTestDB(t)

	queueID, err := EnqueueDownload("vid_cancel", "", 0, "")
	if err != nil {
		t.Fatalf("EnqueueDownload failed: %v", err)
	}

	// Cancel before it gets processed
	if err := CancelDownload(queueID); err != nil {
		t.Fatalf("CancelDownload failed: %v", err)
	}

	var status string
	err = DB.QueryRow("SELECT status FROM download_queue WHERE id = ?", queueID).Scan(&status)
	if err != nil || status != "cancelled" {
		t.Fatalf("expected status 'cancelled', got %q", status)
	}

	// Worker should find no pending downloads
	worked, err := processNextDownload(context.Background())
	if err != nil {
		t.Fatalf("processNextDownload returned error: %v", err)
	}
	if worked {
		t.Fatalf("expected worker to skip cancelled download")
	}
}

func TestDownloadQueueCancellationWhileRunning(t *testing.T) {
	setupTestDB(t)

	oldRunner := commandRunner
	defer func() { commandRunner = oldRunner }()
	commandRunner = mockCommandRunner("sleep")

	queueID, err := EnqueueDownload("vid_slow", "", 0, "")
	if err != nil {
		t.Fatalf("EnqueueDownload failed: %v", err)
	}

	errChan := make(chan error, 1)
	go func() {
		_, pErr := processNextDownload(context.Background())
		errChan <- pErr
	}()

	// Wait briefly for process to start and register cancel func
	time.Sleep(50 * time.Millisecond)

	// Cancel the running download
	if err := CancelDownload(queueID); err != nil {
		t.Fatalf("CancelDownload failed: %v", err)
	}

	select {
	case <-errChan:
	case <-time.After(3 * time.Second):
		t.Fatalf("worker did not abort in time after cancellation")
	}

	var status string
	err = DB.QueryRow("SELECT status FROM download_queue WHERE id = ?", queueID).Scan(&status)
	if err != nil || status != "cancelled" {
		t.Fatalf("expected status 'cancelled', got %q", status)
	}
}
