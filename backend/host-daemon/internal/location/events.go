package location

// WebhookPayload is sent to the physical-world endpoint (Home Assistant)
// when a geofence triggers. Rules in internal/automations fire it.
type WebhookPayload struct {
	Event    string `json:"event"`
	DeviceID string `json:"device_id"`
	Zone     string `json:"zone"`
}

// LocationEnterEvent is the payload of the "location:enter" bus event.
type LocationEnterEvent struct {
	DeviceID string
	Fences   []TriggeredGeofence
}