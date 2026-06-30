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
