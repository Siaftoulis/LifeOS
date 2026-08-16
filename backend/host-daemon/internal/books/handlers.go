package books

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"

	"lifeos/host-daemon/internal/auth/middleware"
	"lifeos/host-daemon/internal/bus"
	"lifeos/host-daemon/internal/books/sources"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/books", HandleBooks)
	mux.HandleFunc("/api/v1/books/{id}", HandleBookByID)
	mux.HandleFunc("/api/v1/books/progress", SyncProgressHandler)
	mux.HandleFunc("/api/v1/books/highlight", SyncHighlightHandler)
	mux.HandleFunc("/api/v1/books/stream", StreamAudiobookHandler)
	mux.HandleFunc("/api/v1/books/{id}/file", HandleBookFile)
	mux.HandleFunc("/api/v1/books/kindle", KindleWebPortalHandler)
	mux.HandleFunc("/api/v1/books/search", HandleSourceSearch)
	mux.HandleFunc("/api/v1/books/download", HandleDownload)
	mux.HandleFunc("/api/v1/books/downloads", HandleDownloads)
	mux.HandleFunc("/api/v1/books/ai/describe", HandleAIDescribe)
	mux.HandleFunc("/api/v1/books/ai/summarize", HandleAISummarize)
	mux.HandleFunc("/api/v1/books/ai/chat", HandleAIChat)
	mux.HandleFunc("/api/v1/books/ai/status", HandleAIStatus)
}

// HandleSourceSearch runs the aggregated source search (Gutenberg, Open
// Library, MangaDex, Anna's Archive) and returns normalized results.
func HandleSourceSearch(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var payload struct {
		Query string `json:"query"`
	}
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil || strings.TrimSpace(payload.Query) == "" {
		http.Error(w, "Missing query", http.StatusBadRequest)
		return
	}
	results := sources.Search(r.Context(), strings.TrimSpace(payload.Query))
	if results == nil {
		results = []sources.Result{}
	}
	json.NewEncoder(w).Encode(results)
}

// HandleDownload starts a background download for one search result.
func HandleDownload(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var payload struct {
		URL    string `json:"url"`
		Title  string `json:"title"`
		Author string `json:"author"`
		Format string `json:"format"`
	}
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil || payload.URL == "" || payload.Title == "" {
		http.Error(w, "url and title required", http.StatusBadRequest)
		return
	}
	if payload.Format == "" {
		payload.Format = "epub"
	}
	job, err := EnqueueDownload(DownloadJob{
		URL: payload.URL, Title: payload.Title, Author: payload.Author, Format: payload.Format,
	})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	json.NewEncoder(w).Encode(job)
}

// HandleBookFile serves the raw book file (EPUB/CBZ) for local readers.
func HandleBookFile(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var filePath string
	err := DB.QueryRow("SELECT file_path FROM books WHERE id = ?", r.PathValue("id")).Scan(&filePath)
	if err != nil || filePath == "" {
		http.Error(w, "Book file not found", http.StatusNotFound)
		return
	}
	http.ServeFile(w, r, filePath)
}

// HandleDownloads lists all download jobs with live progress.
func HandleDownloads(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	jobs, err := ListDownloads()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if jobs == nil {
		jobs = []DownloadJob{}
	}
	json.NewEncoder(w).Encode(jobs)
}

// HandleAIStatus reports whether the local LLM is reachable, so the UI can
// show a live AI online/offline state instead of failing silently.
func HandleAIStatus(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	available, model := LLMStatus()
	json.NewEncoder(w).Encode(map[string]any{"available": available, "model": model})
}

// aiBody is the shared payload for the three AI endpoints.
type aiBody struct {
	BookID   string `json:"book_id"`
	Title    string `json:"title"`  // used when no book_id (describe standalone)
	Author   string `json:"author"` // used when no book_id
	Question string `json:"question"`
}

func loadBookForAI(body aiBody) (title, author, excerpt string, err error) {
	if body.BookID != "" {
		var filePath string
		err = DB.QueryRow("SELECT title, author, file_path FROM books WHERE id = ?", body.BookID).
			Scan(&title, &author, &filePath)
		if err != nil {
			return "", "", "", err
		}
		if chs, e := chapterForBook(body.BookID); e == nil && len(chs) > 0 {
			excerpt = chs[0].Text
		}
		return title, author, excerpt, nil
	}
	return body.Title, body.Author, "", nil
}

// HandleAIDescribe generates description + tags + rating via the local LLM
// and, when a book_id is given, persists them on the book row.
func HandleAIDescribe(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var body aiBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "Bad Request", http.StatusBadRequest)
		return
	}
	title, author, _, err := loadBookForAI(body)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}
	if title == "" {
		http.Error(w, "book_id or title required", http.StatusBadRequest)
		return
	}
	m, err := DescribeBook(title, author)
	if err != nil {
		http.Error(w, "AI describe failed: "+err.Error(), http.StatusBadGateway)
		return
	}
	if body.BookID != "" {
		saveBookMetadata(body.BookID, m)
	}
	json.NewEncoder(w).Encode(m)
}

// HandleAISummarize summarizes the book from its opening excerpt.
func HandleAISummarize(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var body aiBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "Bad Request", http.StatusBadRequest)
		return
	}
	title, _, excerpt, err := loadBookForAI(body)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}
	if excerpt == "" {
		http.Error(w, "no extractable text (needs an EPUB file)", http.StatusUnprocessableEntity)
		return
	}
	sum, err := SummarizeBook(title, excerpt)
	if err != nil {
		http.Error(w, "AI summarize failed: "+err.Error(), http.StatusBadGateway)
		return
	}
	json.NewEncoder(w).Encode(map[string]string{"summary": sum})
}

// HandleAIChat answers a question using the best-matching chapter as context.
func HandleAIChat(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var body aiBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || strings.TrimSpace(body.Question) == "" {
		http.Error(w, "book_id and question required", http.StatusBadRequest)
		return
	}
	title, _, _, err := loadBookForAI(body)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}
	chs, err := chapterForBook(body.BookID)
	if err != nil || len(chs) == 0 {
		http.Error(w, "no extractable text (needs an EPUB file)", http.StatusUnprocessableEntity)
		return
	}
	best := bestChapter(chs, body.Question)
	if best == nil {
		http.Error(w, "no chapter matched", http.StatusUnprocessableEntity)
		return
	}
	reply, err := ChatWithBook(title, best.Title, best.Text, body.Question)
	if err != nil {
		http.Error(w, "AI chat failed: "+err.Error(), http.StatusBadGateway)
		return
	}
	json.NewEncoder(w).Encode(map[string]string{"chapter": best.Title, "answer": reply})
}

// HandleBooks serves GET (list + search) and POST (upsert a book pushed from
// the client's local Drift store).
func HandleBooks(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	switch r.Method {
	case http.MethodGet:
		query := "SELECT id, title, author, current_page, total_pages, file_path, status, cover, description, rating FROM books"
		var args []any
		if q := strings.TrimSpace(r.URL.Query().Get("q")); q != "" {
			query += " WHERE title LIKE ? OR author LIKE ?"
			args = append(args, "%"+q+"%", "%"+q+"%")
		}
		query += " ORDER BY title"

		rows, err := DB.Query(query, args...)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		defer rows.Close()

		var books []Book
		for rows.Next() {
			var b Book
			if err := rows.Scan(&b.ID, &b.Title, &b.Author, &b.CurrentPage, &b.TotalPages, &b.FilePath, &b.Status, &b.Cover, &b.Description, &b.Rating); err == nil {
				books = append(books, b)
			}
		}

		if books == nil {
			books = []Book{}
		}

		json.NewEncoder(w).Encode(books)

	case http.MethodPost:
		var b Book
		if err := json.NewDecoder(r.Body).Decode(&b); err != nil || b.ID == "" || b.Title == "" {
			http.Error(w, "Bad Request (id and title required)", http.StatusBadRequest)
			return
		}
		if b.Status == "" {
			b.Status = "NOT_STARTED"
		}
		if !validBookStatuses[b.Status] {
			http.Error(w, "status must be one of NOT_STARTED, READING, FINISHED", http.StatusBadRequest)
			return
		}
		_, err := DB.Exec(`INSERT INTO books (id, title, author, current_page, total_pages, file_path, status)
			VALUES (?, ?, ?, ?, ?, ?, ?)
			ON CONFLICT(id) DO UPDATE SET title=excluded.title, author=excluded.author,
				current_page=excluded.current_page, total_pages=excluded.total_pages,
				file_path=excluded.file_path, status=excluded.status`,
			b.ID, b.Title, b.Author, b.CurrentPage, b.TotalPages, b.FilePath, b.Status)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		json.NewEncoder(w).Encode(b)

	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

var validBookStatuses = map[string]bool{
	"NOT_STARTED": true, "READING": true, "FINISHED": true,
}

// FinishedEvent is the payload of the "books:finished" bus event.
type FinishedEvent struct {
	BookID string
	UserID string
}

// HandleBookByID serves GET /api/v1/books/{id} and PUT /api/v1/books/{id}
// (status update) for single-book reads and embed cards.
func HandleBookByID(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	id := r.PathValue("id")

	switch r.Method {
	case http.MethodGet:
		row := DB.QueryRow("SELECT id, title, author, current_page, total_pages, file_path, status, cover, description, rating FROM books WHERE id = ?", id)
		var b Book
		if err := row.Scan(&b.ID, &b.Title, &b.Author, &b.CurrentPage, &b.TotalPages, &b.FilePath, &b.Status, &b.Cover, &b.Description, &b.Rating); err != nil {
			http.Error(w, "Book not found", http.StatusNotFound)
			return
		}
		json.NewEncoder(w).Encode(b)

	case http.MethodPut:
		var payload struct {
			Status string `json:"status"`
		}
		if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
			http.Error(w, "Bad Request", http.StatusBadRequest)
			return
		}
		status := strings.ToUpper(strings.TrimSpace(payload.Status))
		if !validBookStatuses[status] {
			http.Error(w, "status must be one of NOT_STARTED, READING, FINISHED", http.StatusBadRequest)
			return
		}
		res, err := DB.Exec("UPDATE books SET status = ? WHERE id = ?", status, id)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		if n, _ := res.RowsAffected(); n == 0 {
			http.Error(w, "Book not found", http.StatusNotFound)
			return
		}
		if status == "FINISHED" {
			userID, _ := r.Context().Value(middleware.UserContextKey).(string)
			bus.Publish(bus.Event{
				Topic:   "books:finished",
				UserID:  userID,
				Payload: FinishedEvent{BookID: id, UserID: userID},
			})
		}
		fmt.Fprintf(w, `{"status":"%s"}`, status)

	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func SyncProgressHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var req ReadingProgress
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	_, err := DB.Exec("INSERT INTO reading_progress (book_id, page, seconds) VALUES (?, ?, ?) ON CONFLICT(book_id) DO UPDATE SET page=?, seconds=?",
		req.BookID, req.Page, req.Seconds, req.Page, req.Seconds)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	_, err = DB.Exec("UPDATE books SET current_page = ? WHERE id = ?", req.Page, req.BookID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"status":"ok"}`))
}

func SyncHighlightHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var req BookHighlight
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	_, err := DB.Exec("INSERT INTO book_highlights (id, book_id, text_content, note_content, page_number) VALUES (?, ?, ?, ?, ?)",
		req.ID, req.BookID, req.TextContent, req.NoteContent, req.PageNumber)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"status":"ok"}`))
}
