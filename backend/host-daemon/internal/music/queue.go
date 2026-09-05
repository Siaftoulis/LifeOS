package music

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"

	"lifeos/host-daemon/internal/bus"
	"lifeos/host-daemon/internal/points"
)

var (
	runningDownloadsMu sync.Mutex
	runningDownloads   = make(map[string]context.CancelFunc)

	queuedUsersMu sync.Mutex
	queuedUsers   = make(map[string]string)

	queueNotify    = make(chan struct{}, 1)
	workerStopChan chan struct{}
	workerOnce     sync.Once
)

func getCacheDir() string {
	base := DataDir
	if base == "" {
		base = "./data"
	}
	return filepath.Join(base, "music_cache")
}

func getLibraryDir() string {
	base := DataDir
	if base == "" {
		base = "./data"
	}
	return filepath.Join(base, "media", "music")
}

func notifyQueue() {
	select {
	case queueNotify <- struct{}{}:
	default:
	}
}

// StartQueueWorker launches the background download worker loop if not already running.
func StartQueueWorker() {
	workerOnce.Do(func() {
		workerStopChan = make(chan struct{})
		if DB != nil {
			// Reset any downloads left hanging in "downloading" from a previous daemon run.
			_, _ = DB.Exec("UPDATE download_queue SET status = 'pending' WHERE status = 'downloading'")
		}
		go queueWorkerLoop()
	})
}

// StopQueueWorker stops the background worker (used primarily in tests).
func StopQueueWorker() {
	if workerStopChan != nil {
		select {
		case <-workerStopChan:
		default:
			close(workerStopChan)
		}
	}
}

// EnqueueDownload registers a track into the download_queue table and notifies the worker.
func EnqueueDownload(videoID string, thumbnail string, priority int, user string) (string, error) {
	if DB == nil {
		return "", fmt.Errorf("database not initialized")
	}

	rawURL := strings.TrimSpace(videoID)
	if !strings.HasPrefix(rawURL, "http://") && !strings.HasPrefix(rawURL, "https://") {
		rawURL = "https://www.youtube.com/watch?v=" + rawURL
	}

	id := "dl-" + strconv.FormatInt(time.Now().UnixNano(), 36)
	now := time.Now().UnixMilli()

	_, err := DB.Exec(`INSERT INTO download_queue (id, track_id, url, status, priority, wifi_only, charging_only, created_at)
		VALUES (?, ?, ?, 'pending', ?, 0, 0, ?)`,
		id, videoID, rawURL, priority, now)
	if err != nil {
		return "", fmt.Errorf("enqueue failed: %w", err)
	}

	if user != "" {
		queuedUsersMu.Lock()
		queuedUsers[id] = user
		queuedUsersMu.Unlock()
	}

	notifyQueue()
	return id, nil
}

// CancelDownload cancels a pending or currently active download.
func CancelDownload(id string) error {
	if DB == nil {
		return fmt.Errorf("database not initialized")
	}

	runningDownloadsMu.Lock()
	cancel, running := runningDownloads[id]
	runningDownloadsMu.Unlock()

	if running && cancel != nil {
		cancel()
	}

	now := time.Now().UnixMilli()
	_, err := DB.Exec("UPDATE download_queue SET status = 'cancelled', completed_at = ?, error_message = 'Cancelled by user' WHERE id = ?", now, id)
	return err
}

func queueWorkerLoop() {
	for {
		select {
		case <-workerStopChan:
			return
		case <-queueNotify:
		case <-time.After(5 * time.Second):
		}

		for {
			if DB == nil {
				break
			}
			worked, _ := processNextDownload(context.Background())
			if !worked {
				break
			}
		}
	}
}

// processNextDownload selects and executes the next pending download item.
func processNextDownload(baseCtx context.Context) (bool, error) {
	if DB == nil {
		return false, nil
	}

	var id, trackID, rawURL string
	var priority int
	err := DB.QueryRow(`
		SELECT id, track_id, url, priority FROM download_queue
		WHERE status = 'pending'
		ORDER BY priority DESC, created_at ASC
		LIMIT 1
	`).Scan(&id, &trackID, &rawURL, &priority)

	if err == sql.ErrNoRows {
		return false, nil
	}
	if err != nil {
		return false, err
	}

	now := time.Now().UnixMilli()
	res, err := DB.Exec("UPDATE download_queue SET status = 'downloading', started_at = ? WHERE id = ? AND status = 'pending'", now, id)
	if err != nil {
		return false, err
	}
	rowsAffected, _ := res.RowsAffected()
	if rowsAffected == 0 {
		return true, nil // Picked up by another worker or cancelled
	}

	// Prepare execution context with timeout and cancellation handle
	ctx, cancel := context.WithTimeout(baseCtx, defaultDownloadTimeout)
	defer cancel()

	runningDownloadsMu.Lock()
	runningDownloads[id] = cancel
	runningDownloadsMu.Unlock()

	defer func() {
		runningDownloadsMu.Lock()
		delete(runningDownloads, id)
		runningDownloadsMu.Unlock()
	}()

	// Ensure target directory exists
	outDir := getLibraryDir()
	if mkErr := os.MkdirAll(outDir, 0755); mkErr != nil {
		log.Printf("music download %s: mkdir failed: %v", trackID, mkErr)
	}

	args := []string{
		"--js-runtimes", jsRuntimesArg(),
		"--no-warnings",
		"--no-check-certificates",
		"--extractor-args", "youtube:player_client=mweb,web,ios,android,tv",
		"-x", "--audio-format", "mp3", "--audio-quality", "0",
		"--embed-metadata", "--embed-thumbnail", "--add-metadata",
		"--print", "after_move:filepath",
		"--print", "after_move:title",
		"--print", "after_move:artist",
		"--print", "after_move:album",
		"--print", "after_move:duration",
		"--print", "after_move:uploader",
		"--print", "after_move:thumbnail",
		"-o", filepath.Join(outDir, "%(artist,uploader)s", "%(title)s [%(id)s].%(ext)s"),
		rawURL,
	}

	out, err := ExecYtDlp(ctx, "download", trackID, args)
	completedAt := time.Now().UnixMilli()

	if errors.Is(ctx.Err(), context.Canceled) {
		log.Printf("music download %s: cancelled", trackID)
		_, _ = DB.Exec("UPDATE download_queue SET status = 'cancelled', completed_at = ?, error_message = 'Download cancelled' WHERE id = ?", completedAt, id)
		return true, nil
	}

	if err != nil {
		errMsg := err.Error()
		log.Printf("music download %s failed: %s", trackID, errMsg)
		_, _ = DB.Exec("UPDATE download_queue SET status = 'failed', completed_at = ?, error_message = ? WHERE id = ?", completedAt, errMsg, id)
		return true, err
	}

	lines := strings.Split(strings.TrimSpace(string(out)), "\n")
	if len(lines) < 6 || lines[0] == "" {
		errMsg := fmt.Sprintf("unexpected yt-dlp output format (%d lines)", len(lines))
		log.Printf("music download %s: %s", trackID, errMsg)
		_, _ = DB.Exec("UPDATE download_queue SET status = 'failed', completed_at = ?, error_message = ? WHERE id = ?", completedAt, errMsg, id)
		return true, fmt.Errorf("%s", errMsg)
	}

	clean := func(s string) string {
		s = strings.TrimSpace(s)
		if s == "NA" {
			return ""
		}
		return s
	}

	savedPath := clean(lines[0])
	title := clean(lines[1])
	artist := clean(lines[2])
	album := clean(lines[3])
	duration := 0.0
	if d, parseErr := strconv.ParseFloat(strings.TrimSpace(lines[4]), 64); parseErr == nil {
		duration = d
	}
	uploader := clean(lines[5])
	if artist == "" {
		artist = uploader
	}
	thumb := ""
	if len(lines) >= 7 {
		thumb = clean(lines[6])
	}
	if thumb == "" {
		thumb = "https://i.ytimg.com/vi/" + trackID + "/hqdefault.jpg"
	}

	// Update music_tracks table with canonical thumbnail and thumbnail_url
	_, dbErr := DB.Exec(`INSERT INTO music_tracks (id, title, artist, album, file_path, duration, thumbnail, thumbnail_url)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(id) DO UPDATE SET title=excluded.title, artist=excluded.artist,
		album=excluded.album, file_path=excluded.file_path, duration=excluded.duration,
		thumbnail=excluded.thumbnail, thumbnail_url=excluded.thumbnail_url`,
		trackID, title, artist, album, savedPath, duration, thumb, thumb)
	if dbErr != nil {
		log.Printf("music download %s: db insert failed: %v", trackID, dbErr)
		_, _ = DB.Exec("UPDATE download_queue SET status = 'failed', completed_at = ?, error_message = ? WHERE id = ?", completedAt, dbErr.Error(), id)
		return true, dbErr
	}

	// Update queue status to completed
	_, _ = DB.Exec("UPDATE download_queue SET status = 'completed', completed_at = ?, destination_path = ? WHERE id = ?", completedAt, savedPath, id)

	queuedUsersMu.Lock()
	user := queuedUsers[id]
	delete(queuedUsers, id)
	queuedUsersMu.Unlock()

	if user != "" {
		points.AddPointsWithEvent(user, 5, "Music: Track Downloaded: "+title)
	}

	bus.Publish(bus.Event{
		Topic:  "music:downloaded",
		UserID: user,
		Payload: map[string]any{
			"track_id":  trackID,
			"title":     title,
			"artist":    artist,
			"album":     album,
			"duration":  duration,
			"file_path": savedPath,
		},
	})

	log.Printf("music download done: %s - %s -> %s", artist, title, savedPath)
	return true, nil
}
