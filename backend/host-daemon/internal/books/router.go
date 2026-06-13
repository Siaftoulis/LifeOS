package books

import (
	"net/http"
)

// RegisterRoutes mounts all book-related endpoints into the main mux.
func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/books", ListBooksHandler)
	mux.HandleFunc("/api/v1/books/progress", SyncProgressHandler)
	mux.HandleFunc("/api/v1/books/highlight", SyncHighlightHandler)
	mux.HandleFunc("/api/v1/books/stream", StreamAudiobookHandler)
	mux.HandleFunc("/api/v1/books/kindle", KindleWebPortalHandler)
}

func ListBooksHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`[{"id":"1","title":"Stub Book","author":"Unknown"}]`))
}

func SyncProgressHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status":"ok"}`))
}

func SyncHighlightHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status":"ok"}`))
}
