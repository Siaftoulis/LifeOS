package books

import (
	"encoding/json"
	"net/http"
	"os"
	"path/filepath"
	"sync"
)

var (
	dbMutex sync.Mutex
	dbPath  = filepath.Join("data", "books.json")
)

type Book struct {
	ID          string `json:"id"`
	Title       string `json:"title"`
	Author      string `json:"author"`
	CurrentPage int    `json:"current_page"`
	TotalPages  int    `json:"total_pages"`
	FilePath    string `json:"file_path"`
}

type ReadingProgress struct {
	BookID  string `json:"book_id"`
	Page    int    `json:"page"`
	Seconds int    `json:"seconds"`
}

type BookHighlight struct {
	ID          string `json:"id"`
	BookID      string `json:"book_id"`
	TextContent string `json:"text_content"`
	NoteContent string `json:"note_content"`
	PageNumber  int    `json:"page_number"`
}

type BooksDB struct {
	Books      []Book            `json:"books"`
	Progress   []ReadingProgress `json:"progress"`
	Highlights []BookHighlight   `json:"highlights"`
}

func loadDB() (*BooksDB, error) {
	os.MkdirAll("data", 0755)
	file, err := os.Open(dbPath)
	if err != nil {
		if os.IsNotExist(err) {
			// Seed default data
			return &BooksDB{
				Books: []Book{
					{ID: "book-1", Title: "The Pragmatic Programmer", Author: "Andrew Hunt", TotalPages: 320, FilePath: "storage/books/pragmatic.epub"},
					{ID: "book-2", Title: "Clean Code", Author: "Robert C. Martin", TotalPages: 464, FilePath: "storage/books/cleancode.epub"},
				},
				Progress:   []ReadingProgress{},
				Highlights: []BookHighlight{},
			}, nil
		}
		return nil, err
	}
	defer file.Close()
	var db BooksDB
	if err := json.NewDecoder(file).Decode(&db); err != nil {
		return nil, err
	}
	return &db, nil
}

func saveDB(db *BooksDB) error {
	os.MkdirAll("data", 0755)
	file, err := os.Create(dbPath)
	if err != nil {
		return err
	}
	defer file.Close()
	return json.NewEncoder(file).Encode(db)
}

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/books", ListBooksHandler)
	mux.HandleFunc("/api/v1/books/progress", SyncProgressHandler)
	mux.HandleFunc("/api/v1/books/highlight", SyncHighlightHandler)
	mux.HandleFunc("/api/v1/books/stream", StreamAudiobookHandler)
	mux.HandleFunc("/api/v1/books/kindle", KindleWebPortalHandler)
}

func ListBooksHandler(w http.ResponseWriter, r *http.Request) {
	dbMutex.Lock()
	defer dbMutex.Unlock()
	db, err := loadDB()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(db.Books)
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

	dbMutex.Lock()
	defer dbMutex.Unlock()
	db, err := loadDB()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Update progress list
	found := false
	for i, p := range db.Progress {
		if p.BookID == req.BookID {
			db.Progress[i] = req
			found = true
			break
		}
	}
	if !found {
		db.Progress = append(db.Progress, req)
	}

	// Update corresponding book current page if matched
	for i, b := range db.Books {
		if b.ID == req.BookID {
			db.Books[i].CurrentPage = req.Page
			break
		}
	}

	if err := saveDB(db); err != nil {
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

	dbMutex.Lock()
	defer dbMutex.Unlock()
	db, err := loadDB()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	db.Highlights = append(db.Highlights, req)
	if err := saveDB(db); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"status":"ok"}`))
}
