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
		json.NewEncoder(w).Encode(defaultGeofences())
		return
	}
	
	if r.Method == http.MethodPost {
		// Mock saving geofence
		var geo Geofence
		json.NewDecoder(r.Body).Decode(&geo)
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
	// Return a dummy route for now
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "success",
		"route": []map[string]float64{
			{"lat": 37.9838, "lon": 23.7275},
			{"lat": 37.9850, "lon": 23.7300},
			{"lat": 37.9870, "lon": 23.7350},
		},
	})
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

	triggered := checkProximity(report, defaultGeofences())
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
		"status":             "success",
		"triggered_geofences": triggered,
		"geofence_count":     len(triggered),
	}

	if len(triggered) > 0 {
		log.Printf("Geofence triggered by %s: %+v", report.DeviceID, triggered)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}
