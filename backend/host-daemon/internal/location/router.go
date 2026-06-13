package location

import (
	"encoding/json"
	"log"
	"net/http"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/radar/geofences", HandleGetGeofences)
	mux.HandleFunc("/api/v1/radar/report", HandleReportLocation)
	mux.HandleFunc("/api/v1/radar/live", HandleLiveRadar)
}

func HandleGetGeofences(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode([]map[string]interface{}{
		{"id": "g1", "name": "Home Base", "lat": 37.9838, "lon": 23.7275, "radius": 150},
	})
}

func HandleReportLocation(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":             "success",
		"triggered_webhooks": 0,
	})
}

func HandleLiveRadar(w http.ResponseWriter, r *http.Request) {
	log.Println("Radar WebSocket connection requested")
	// Stub implementation - waiting for gorilla/websocket or equivalent
	w.WriteHeader(http.StatusUpgradeRequired)
	w.Write([]byte("Upgrade Required for WebSocket"))
}
