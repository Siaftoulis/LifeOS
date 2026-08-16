package books

import (
	"context"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"lifeos/host-daemon/internal/bus"
)

// DownloadJob is a row of the download_jobs table (status PENDING ->
// DOWNLOADING -> DONE | FAILED).
type DownloadJob struct {
	ID            string `json:"id"`
	URL           string `json:"url"`
	Title         string `json:"title"`
	Author        string `json:"author"`
	Format        string `json:"format"`
	Status        string `json:"status"`
	ProgressBytes int64  `json:"progress_bytes"`
	TotalBytes    int64  `json:"total_bytes"`
	FilePath      string `json:"file_path"`
	Error         string `json:"error,omitempty"`
	CreatedAt     int64  `json:"created_at"`
	UpdatedAt     int64  `json:"updated_at"`
}

// dlMutex guards the in-memory job cache. The DB is the source of truth;
// the cache only tracks live progress (progress_bytes) of active jobs.
var (
	dlMutex   sync.Mutex
	dlActive  = map[string]*DownloadJob{}
	booksDir  = "storage/books"
	dlTimeout = 30 * time.Minute
)

// EnqueueDownload inserts a job row and starts the background download.
func EnqueueDownload(job DownloadJob) (DownloadJob, error) {
	job.ID = "dl-" + fmt.Sprintf("%d", time.Now().UnixNano())
	job.Status = "PENDING"
	now := time.Now().Unix()
	job.CreatedAt, job.UpdatedAt = now, now
	if job.Format == "" {
		job.Format = "epub"
	}

	_, err := DB.Exec(`INSERT INTO download_jobs
		(id, url, title, author, format, status, progress_bytes, total_bytes, file_path, error, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, 0, 0, '', '', ?, ?)`,
		job.ID, job.URL, job.Title, job.Author, job.Format, job.Status, now, now)
	if err != nil {
		return DownloadJob{}, err
	}

	go runDownload(job.ID)
	return job, nil
}

// runDownload performs the actual HTTP download, writing to booksDir and
// updating both the DB row and the live cache.
func runDownload(id string) {
	dlMutex.Lock()
	// Re-read the row so the goroutine owns its own copy.
	row := DB.QueryRow("SELECT id, url, title, author, format, file_path FROM download_jobs WHERE id = ?", id)
	var job DownloadJob
	if err := row.Scan(&job.ID, &job.URL, &job.Title, &job.Author, &job.Format, &job.FilePath); err != nil {
		dlMutex.Unlock()
		log.Printf("download %s: load failed: %v", id, err)
		return
	}
	dlActive[id] = &job
	dlMutex.Unlock()

	updateJob(id, "DOWNLOADING", "", 0)

	// filename from the URL (or a fallback from the title)
	fname := filepath.Base(strings.Split(job.URL, "?")[0])
	if fname == "" || fname == "/" || strings.HasPrefix(fname, "md5") {
		fname = sanitizeFilename(job.Title) + "." + job.Format
	}
	dest := filepath.Join(booksDir, fname)
	if err := os.MkdirAll(booksDir, 0o755); err != nil {
		updateJob(id, "FAILED", fmt.Sprintf("mkdir: %v", err), 0)
		return
	}

	req, err := http.NewRequestWithContext(context.Background(), http.MethodGet, job.URL, nil)
	if err != nil {
		updateJob(id, "FAILED", err.Error(), 0)
		return
	}
	req.Header.Set("User-Agent", "Mozilla/5.0 (LifeOS host daemon; self-hosted)")
	client := &http.Client{Timeout: dlTimeout}

	resp, err := client.Do(req)
	if err != nil {
		updateJob(id, "FAILED", err.Error(), 0)
		return
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		updateJob(id, "FAILED", fmt.Sprintf("status %d", resp.StatusCode), 0)
		return
	}

	out, err := os.Create(dest)
	if err != nil {
		updateJob(id, "FAILED", err.Error(), 0)
		return
	}
	defer out.Close()

	job.TotalBytes = resp.ContentLength
	n, copyErr := io.Copy(io.MultiWriter(out, &progressWriter{id: id}), resp.Body)
	dlMutex.Lock()
	job.ProgressBytes = n
	dlMutex.Unlock()
	if copyErr != nil {
		os.Remove(dest)
		updateJob(id, "FAILED", copyErr.Error(), 0)
		return
	}

	updateJob(id, "DONE", dest, n)
	importDownloadedBook(id)
}

// progressWriter feeds live bytes into the shared cache.
type progressWriter struct{ id string }

func (p *progressWriter) Write(b []byte) (int, error) {
	dlMutex.Lock()
	if j, ok := dlActive[p.id]; ok {
		j.ProgressBytes += int64(len(b))
	}
	dlMutex.Unlock()
	return len(b), nil
}

func updateJob(id, status, detail string, bytes int64) {
	dlMutex.Lock()
	if j, ok := dlActive[id]; ok {
		j.Status = status
		if detail != "" && status == "FAILED" {
			j.Error = detail
		}
		if bytes > 0 {
			j.ProgressBytes = bytes
		}
	}
	dlMutex.Unlock()

	now := time.Now().Unix()
	if status == "DONE" || status == "FAILED" {
		filePath, errMsg := "", ""
		if status == "DONE" {
			filePath = detail
		} else {
			errMsg = detail
		}
		_, err := DB.Exec(`UPDATE download_jobs SET status=?, file_path=?, error=?, progress_bytes=?, updated_at=? WHERE id=?`,
			status, filePath, errMsg, bytes, now, id)
		if err != nil {
			log.Printf("download %s: update failed: %v", id, err)
		}
	} else {
		_, err := DB.Exec(`UPDATE download_jobs SET status=?, updated_at=? WHERE id=?`, status, now, id)
		if err != nil {
			log.Printf("download %s: update failed: %v", id, err)
		}
	}
}

// importDownloadedBook adds the finished file to the books table and
// publishes a "books:downloaded" bus event (notifications/points hooks).
func importDownloadedBook(id string) {
	dlMutex.Lock()
	job := dlActive[id]
	dlMutex.Unlock()
	if job == nil {
		return
	}

	bookID := "bk-" + strings.TrimPrefix(id, "dl-")
	_, err := DB.Exec(`INSERT INTO books (id, title, author, current_page, total_pages, file_path, status)
		VALUES (?, ?, ?, 0, 0, ?, 'NOT_STARTED')
		ON CONFLICT(id) DO NOTHING`,
		bookID, job.Title, job.Author, job.FilePath)
	if err != nil {
		log.Printf("download %s: import failed: %v", id, err)
		return
	}
	bus.Publish(bus.Event{Topic: "books:downloaded", Payload: map[string]string{"book_id": bookID, "title": job.Title}})
}

// ListDownloads returns all job rows, newest first, with live progress
// merged in from the cache.
func ListDownloads() ([]DownloadJob, error) {
	rows, err := DB.Query("SELECT id, url, title, author, format, status, progress_bytes, total_bytes, file_path, error, created_at, updated_at FROM download_jobs ORDER BY created_at DESC")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var jobs []DownloadJob
	for rows.Next() {
		var j DownloadJob
		if err := rows.Scan(&j.ID, &j.URL, &j.Title, &j.Author, &j.Format, &j.Status, &j.ProgressBytes, &j.TotalBytes, &j.FilePath, &j.Error, &j.CreatedAt, &j.UpdatedAt); err != nil {
			return nil, err
		}
		dlMutex.Lock()
		if live, ok := dlActive[j.ID]; ok {
			j.Status = live.Status
			j.ProgressBytes = live.ProgressBytes
			j.TotalBytes = live.TotalBytes
		}
		dlMutex.Unlock()
		jobs = append(jobs, j)
	}
	return jobs, nil
}

func sanitizeFilename(s string) string {
	replacer := strings.NewReplacer("/", "_", "\\", "_", ":", "_", "*", "_", "?", "_", "\"", "_", "<", "_", ">", "_", "|", "_")
	return strings.TrimSpace(replacer.Replace(s))
}