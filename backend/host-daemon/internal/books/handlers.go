package books

import (
	"encoding/json"
	"net/http"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/books", ListBooksHandler)
	mux.HandleFunc("/api/v1/books/progress", SyncProgressHandler)
	mux.HandleFunc("/api/v1/books/highlight", SyncHighlightHandler)
	mux.HandleFunc("/api/v1/books/stream", StreamAudiobookHandler)
	mux.HandleFunc("/api/v1/books/kindle", KindleWebPortalHandler)
}

func ListBooksHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	rows, err := DB.Query("SELECT id, title, author, current_page, total_pages, file_path FROM books")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var books []Book
	for rows.Next() {
		var b Book
		if err := rows.Scan(&b.ID, &b.Title, &b.Author, &b.CurrentPage, &b.TotalPages, &b.FilePath); err == nil {
			books = append(books, b)
		}
	}

	if books == nil {
		books = []Book{}
	}

	json.NewEncoder(w).Encode(books)
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
