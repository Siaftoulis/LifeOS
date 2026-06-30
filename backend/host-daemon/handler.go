package main

import (
	"encoding/json"
	"fmt"
	"net/http"

	"lifeos/host-daemon/crypto"
)

// handleAction processes incoming RPC requests
func handleAction(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
		return
	}

	var payload ActionPayload
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		http.Error(w, "Invalid JSON payload", http.StatusBadRequest)
		return
	}

	if payload.Signature == "" {
		http.Error(w, "Unauthorized: Missing Signature", http.StatusUnauthorized)
		return
	}

	// Verify the HMAC signature based on ActionType and TargetID
	if !crypto.VerifyHMAC(payload.ActionType+payload.TargetID, payload.Signature) {
		http.Error(w, "Unauthorized: Invalid Signature", http.StatusUnauthorized)
		return
	}

	var message string
	var err error

	// Route the requested command
	switch payload.ActionType {
	case "START_VM":
		message, err = StartVM(payload.TargetID)
	case "STOP_VM":
		message, err = StopVM(payload.TargetID)
	case "GET_VMS":
		vms, errGet := GetVirtualMachines()
		if errGet != nil {
			err = errGet
		} else {
			vmsBytes, _ := json.Marshal(vms)
			message = string(vmsBytes)
		}
	case "TRIGGER_WOL":
		errWOL := BroadcastMagicPacket(payload.TargetID)
		if errWOL != nil {
			err = errWOL
		} else {
			message = fmt.Sprintf("WOL Magic Packet fired for MAC: %s", payload.TargetID)
		}
	default:
		http.Error(w, "Unknown action_type", http.StatusBadRequest)
		return
	}

	status := "Acknowledge"
	if err != nil {
		status = "Error"
		message = err.Error()
	} else if message == "" {
		message = fmt.Sprintf("Command %s executed successfully", payload.ActionType)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(ActionResponse{Status: status, Message: message})
}
