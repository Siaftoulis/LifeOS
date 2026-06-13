package home

import (
	"encoding/json"
	"net/http"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/home/devices", HandleListDevices)
	mux.HandleFunc("/api/v1/home/devices/toggle", HandleToggleDevice)
	mux.HandleFunc("/api/v1/home/sensors/report", HandleSensorReport)
}

func HandleListDevices(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode([]map[string]interface{}{
		{"device_id": "light.living_room", "state": "ON"},
		{"device_id": "climate.thermostat", "state": "HEAT"},
	})
}

func HandleToggleDevice(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	// Stubbed HA action
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "success",
		"message": "Stubbed Device Toggle",
	})
}

func HandleSensorReport(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "received",
	})
}
