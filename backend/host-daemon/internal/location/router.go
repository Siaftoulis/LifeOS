package location

import (
	"encoding/json"
	"log"
	"net/http"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/radar/geofences", HandleGeofences)
	mux.HandleFunc("/api/v1/radar/report", HandleReportLocation)
	mux.HandleFunc("/api/v1/radar/live", HandleLiveRadar)
	mux.HandleFunc("/api/v1/radar/routing", HandleRouting)
}

func HandleGeofences(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodGet {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(GetGeofences())
		return
	}

	if r.Method == http.MethodPost {
		var geo Geofence
		json.NewDecoder(r.Body).Decode(&geo)
		AddGeofence(geo)
		log.Printf("Saved new geofence: %+v", geo)
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"status": "success"})
		return
	}

	http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
}

func HandleRouting(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	// OSRM Integration planned for future. Return proper error for now.
	http.Error(w, "Routing service not configured (OSRM integration pending)", http.StatusNotImplemented)
}

func HandleReportLocation(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var report LocationReport
	if err := json.NewDecoder(r.Body).Decode(&report); err != nil {
		http.Error(w, `{"status":"error","message":"invalid JSON"}`, http.StatusBadRequest)
		return
	}

	if report.Latitude == 0 && report.Longitude == 0 {
		http.Error(w, `{"status":"error","message":"invalid coordinates"}`, http.StatusBadRequest)
		return
	}

	triggered := checkProximity(report, GetGeofences())
	if len(triggered) > 0 {
		TriggerAutomation(report, triggered)
	}

	update := LiveUpdate{
		Type:      "location_report",
		DeviceID:  report.DeviceID,
		Latitude:  report.Latitude,
		Longitude: report.Longitude,
		Velocity:  report.Velocity,
		Altitude:  report.Altitude,
		Timestamp: report.Timestamp,
	}
	DefaultBroker.Broadcast(update)

	resp := map[string]interface{}{
		"status":              "success",
		"triggered_geofences": triggered,
		"geofence_count":      len(triggered),
	}

	if len(triggered) > 0 {
		log.Printf("Geofence triggered by %s: %+v", report.DeviceID, triggered)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}
