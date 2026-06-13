package calendar

import (
	"net/http"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/calendar/events", HandleGetEvents)
	mux.HandleFunc("/api/v1/calendar/events/create", HandleCreateEvent)
	mux.HandleFunc("/api/v1/calendar/live", HandleLiveSync)
}

func HandleGetEvents(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`[]`))
}

func HandleCreateEvent(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"status":"created"}`))
}

func HandleLiveSync(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte(`Upgrade to WebSocket required`))
}
