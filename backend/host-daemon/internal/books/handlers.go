package books

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/books", HandleBooks)
	mux.HandleFunc("/api/v1/books/{id}", HandleBookByID)
	mux.HandleFunc("/api/v1/books/progress", SyncProgressHandler)
	mux.HandleFunc("/api/v1/books/highlight", SyncHighlightHandler)
	mux.HandleFunc("/api/v1/books/stream", StreamAudiobookHandler)
	mux.HandleFunc("/api/v1/books/kindle", KindleWebPortalHandler)
}

// HandleBooks serves GET (list + search) and POST (upsert a book pushed from
// the client's local Drift store).
func HandleBooks(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	switch r.Method {
	case http.MethodGet:
		query := "SELECT id, title, author, current_page, total_pages, file_path, status FROM books"
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
			if err := rows.Scan(&b.ID, &b.Title, &b.Author, &b.CurrentPage, &b.TotalPages, &b.FilePath, &b.Status); err == nil {
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

// HandleBookByID serves GET /api/v1/books/{id} and PUT /api/v1/books/{id}
// (status update) for single-book reads and embed cards.
func HandleBookByID(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	id := r.PathValue("id")

	switch r.Method {
	case http.MethodGet:
		row := DB.QueryRow("SELECT id, title, author, current_page, total_pages, file_path, status FROM books WHERE id = ?", id)
		var b Book
		if err := row.Scan(&b.ID, &b.Title, &b.Author, &b.CurrentPage, &b.TotalPages, &b.FilePath, &b.Status); err != nil {
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
