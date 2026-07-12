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
	
	rows, err := DB.Query("SELECT id, name, type, state FROM devices")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var devices []map[string]interface{}
	for rows.Next() {
		var id, name, dtype, state string
		if err := rows.Scan(&id, &name, &dtype, &state); err == nil {
			devices = append(devices, map[string]interface{}{
				"device_id": id,
				"name":      name,
				"type":      dtype,
				"state":     state,
			})
		}
	}
	json.NewEncoder(w).Encode(devices)
}

func HandleToggleDevice(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	
	var req map[string]string
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	deviceId := req["device_id"]
	
	// Get current state
	var currentState string
	err := DB.QueryRow("SELECT state FROM devices WHERE id = ?", deviceId).Scan(&currentState)
	if err != nil {
		http.Error(w, "device not found", http.StatusNotFound)
		return
	}

	newState := "ON"
	if currentState == "ON" {
		newState = "OFF"
	}

	_, err = DB.Exec("UPDATE devices SET state = ?, updated_at = strftime('%s', 'now') WHERE id = ?", newState, deviceId)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":    "success",
		"device_id": deviceId,
		"state":     newState,
	})
}

func HandleSensorReport(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	
	var req map[string]string
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	sensorId := req["sensor_id"]
	value := req["value"]

	_, err := DB.Exec("INSERT INTO sensor_logs (sensor_id, value, timestamp) VALUES (?, ?, strftime('%s', 'now'))", sensorId, value)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "received",
	})
}
