package location

import (
	"bytes"
	"encoding/json"
	"log"
	"net/http"
	"os"
)

type WebhookPayload struct {
	Event    string `json:"event"`
	DeviceID string `json:"device_id"`
	Zone     string `json:"zone"`
}

// TriggerAutomation hooks into home management or other backend systems
func TriggerAutomation(report LocationReport, fences []TriggeredGeofence) {
	webhookURL := os.Getenv("AUTOMATION_WEBHOOK_URL")
	if webhookURL == "" {
		webhookURL = "http://localhost:8123/api/webhook/lifeos"
	}

	for _, f := range fences {
		log.Printf("[AUTOMATION] User %s entered zone '%s'", report.DeviceID, f.Name)

		payload := WebhookPayload{
			Event:    "zone_entered",
			DeviceID: report.DeviceID,
			Zone:     f.Name,
		}

		data, err := json.Marshal(payload)
		if err == nil {
			go func() {
				_, err := http.Post(webhookURL, "application/json", bytes.NewBuffer(data))
				if err != nil {
					log.Printf("[AUTOMATION] Webhook failed for %s: %v", f.Name, err)
				}
			}()
		}
	}
}
