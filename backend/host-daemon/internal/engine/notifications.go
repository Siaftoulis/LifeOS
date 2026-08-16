package engine

import (
	"fmt"
	"log"
	"time"
)

// DispatchNotifications creates notification entities for everyone an entity
// is shared with or assigned to. Lives in the engine package because it
// writes engine-domain entities; rules trigger it via the bus.
func DispatchNotifications(e Entity) {
	recipients := make(map[string]bool)
	for _, user := range e.SharedWith {
		if user != "" && user != e.CreatorID {
			recipients[user] = true
		}
	}
	if e.AssignedTo != "" && e.AssignedTo != e.CreatorID {
		recipients[e.AssignedTo] = true
	}

	if len(recipients) == 0 {
		return
	}

	title, _ := e.Payload["title"].(string)
	if title == "" {
		title = "Shared Item"
	}
	status, _ := e.Payload["status"].(string)

	now := time.Now()
	for recipient := range recipients {
		var notifTitle, notifMsg string
		if status == "completed" {
			notifTitle = "✨ Task Completed!"
			notifMsg = fmt.Sprintf("%s completed shared task: '%s'", e.CreatorID, title)
		} else {
			notifTitle = "🔔 New Shared Item"
			notifMsg = fmt.Sprintf("%s shared/assigned '%s' with you", e.CreatorID, title)
		}

		notif := Entity{
			ID:        "notif_" + generateID(),
			Type:      TypeNotification,
			CreatorID: e.CreatorID,
			Payload: map[string]interface{}{
				"title":     notifTitle,
				"message":   notifMsg,
				"entity_id": e.ID,
				"read":      false,
				"timestamp": now.Format(time.RFC3339),
			},
			SharedWith: []string{recipient},
			AssignedTo: recipient,
			CreatedAt:  now,
			UpdatedAt:  now,
		}

		SaveEntity(notif)
		log.Printf("-> 🔔 MULTIPLAYER NOTIFICATION DISPATCHED to %s: %s", recipient, notifMsg)
	}
}