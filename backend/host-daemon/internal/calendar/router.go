package calendar

import (
	"encoding/json"
	"net/http"
	"strconv"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/calendar/events", HandleGetEvents)
	mux.HandleFunc("/api/v1/calendar/events/create", HandleCreateEvent)
	mux.HandleFunc("/api/v1/calendar/live", HandleLiveSync)
}

func HandleGetEvents(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	fromStr := r.URL.Query().Get("from")
	toStr := r.URL.Query().Get("to")

	events := GetEvents()

	var fromVal, toVal int64
	var err error
	hasFrom := false
	hasTo := false

	if fromStr != "" {
		fromVal, err = strconv.ParseInt(fromStr, 10, 64)
		if err == nil {
			hasFrom = true
		}
	}
	if toStr != "" {
		toVal, err = strconv.ParseInt(toStr, 10, 64)
		if err == nil {
			hasTo = true
		}
	}

	filtered := make([]CalendarEvent, 0)
	for _, e := range events {
		// Event overlaps range [from, to] if it doesn't end before from, and doesn't start after to
		if hasFrom && e.EndTime < fromVal {
			continue
		}
		if hasTo && e.StartTime > toVal {
			continue
		}
		filtered = append(filtered, e)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(filtered)
}

func HandleCreateEvent(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var event CalendarEvent
	if err := json.NewDecoder(r.Body).Decode(&event); err != nil {
		http.Error(w, "Invalid payload", http.StatusBadRequest)
		return
	}

	CreateEvent(event)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "created",
		"event":  event,
	})
}

func HandleLiveSync(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte(`Upgrade to WebSocket required`))
}
