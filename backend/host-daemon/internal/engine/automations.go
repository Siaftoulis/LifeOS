package engine

import (
	"fmt"
	"log"
	"time"

	"lifeos/host-daemon/internal/points"
)

// RunAutomations hooks into the entity lifecycle to execute background tasks
func RunAutomations(e Entity) {
	log.Printf("[General Engine] Running automations for Entity: %s (Type: %s)", e.ID, e.Type)

	userID := e.CreatorID
	if userID == "" {
		userID = "panospds" // Default user if none specified
	}

	switch e.Type {
	case TypeEvent:
		log.Printf("-> Triggering calendar notifications for Event: %s", e.ID)
		dispatchMultiplayerNotifications(e)
		
	case TypeTask:
		log.Printf("-> Evaluating task auto-assignment constraints for Task: %s", e.ID)
		dispatchMultiplayerNotifications(e)
		// For prototype, award 15 XP for completing a task
		status, _ := e.Payload["status"].(string)
		if status == "completed" {
			points.AddPointsWithEvent(userID, 15, "Completed Task: " + e.ID)
		}

	case TypeHabit:
		log.Printf("-> Processing habit completion for Habit: %s", e.ID)
		status, _ := e.Payload["status"].(string)
		if status == "completed" {
			points.AddPointsWithEvent(userID, 10, "Completed Habit")
		}

	case TypeZenLog:
		log.Printf("-> Processing daily Zen log for User: %s", userID)
		points.AddPointsWithEvent(userID, 20, "Wrote Daily Zen Log")

	case TypeMetric:
		log.Printf("-> Evaluating Metric-Based Task Auto-Assignments for Metric: %s", e.ID)
		metricType, _ := e.Payload["metric_type"].(string)
		val, _ := e.Payload["value"].(float64)
		if val == 0 {
			if intVal, ok := e.Payload["value"].(int); ok {
				val = float64(intVal)
			}
		}

		now := time.Now()

		if metricType == "steps" && val >= 10000 {
			log.Printf("-> 🎯 Auto-completing 10k Steps Goal for User: %s", userID)
			autoTask := Entity{
				ID:        "auto_task_steps_" + now.Format("20060102"),
				Type:      TypeTask,
				CreatorID: userID,
				Payload: map[string]interface{}{
					"title":    "🤖 Completed Daily 10k Steps Goal",
					"status":   "completed",
					"base_xp":  25,
					"due_date": now.Format(time.RFC3339),
				},
				CreatedAt: now,
				UpdatedAt: now,
			}
			SaveEntity(autoTask)
			points.AddPointsWithEvent(userID, 25, "Achieved Daily 10k Steps Goal")

		} else if metricType == "water" && val >= 2.0 {
			log.Printf("-> 💧 Auto-completing Hydration Goal for User: %s", userID)
			autoTask := Entity{
				ID:        "auto_task_water_" + now.Format("20060102"),
				Type:      TypeTask,
				CreatorID: userID,
				Payload: map[string]interface{}{
					"title":    "🤖 Hydration Goal (2L Water)",
					"status":   "completed",
					"base_xp":  15,
					"due_date": now.Format(time.RFC3339),
				},
				CreatedAt: now,
				UpdatedAt: now,
			}
			SaveEntity(autoTask)
			points.AddPointsWithEvent(userID, 15, "Achieved Daily 2L Water Goal")

		} else if metricType == "sleep" && val >= 7.5 {
			log.Printf("-> 🌙 Auto-completing Sleep Goal for User: %s", userID)
			autoTask := Entity{
				ID:        "auto_task_sleep_" + now.Format("20060102"),
				Type:      TypeTask,
				CreatorID: userID,
				Payload: map[string]interface{}{
					"title":    "🤖 Optimal Sleep Goal (7.5h)",
					"status":   "completed",
					"base_xp":  20,
					"due_date": now.Format(time.RFC3339),
				},
				CreatedAt: now,
				UpdatedAt: now,
			}
			SaveEntity(autoTask)
			points.AddPointsWithEvent(userID, 20, "Achieved Daily Sleep Goal")
		}

	case TypeFlashcardReview:
		log.Printf("-> Processing Flashcard Spaced-Repetition Review for User: %s", userID)
		rating, _ := e.Payload["rating"].(float64)
		if rating == 0 {
			if intRating, ok := e.Payload["rating"].(int); ok {
				rating = float64(intRating)
			}
		}
		if rating >= 3 {
			points.AddPointsWithEvent(userID, 5, "Flashcard Spaced-Repetition Success")
		}

	case TypeMediaMovie, TypeYoutubeVideo:
		status, _ := e.Payload["status"].(string)
		if status == "watched" {
			log.Printf("-> 🎬 Media Watchlist Item Completed for User: %s", userID)
			points.AddPointsWithEvent(userID, 10, "Media Watchlist Completion")
		}

	case TypeGeofence:
		event, _ := e.Payload["event"].(string) // "enter", "exit"
		locationName, _ := e.Payload["name"].(string)
		log.Printf("-> 📍 Geofence Event '%s' at '%s' for User: %s", event, locationName, userID)
		if event == "enter" && (locationName == "Gym" || locationName == "Fitness") {
			points.AddPointsWithEvent(userID, 15, "Gym Geofence Arrival")
		}

	case TypeSmartDevice:
		deviceName, _ := e.Payload["name"].(string)
		status, _ := e.Payload["status"].(string)
		log.Printf("-> ⚡ Smart Device '%s' state updated to '%s' by User: %s", deviceName, status, userID)

	case TypeCloudBackup:
		status, _ := e.Payload["status"].(string)
		if status == "completed" {
			log.Printf("-> ☁️ Device Backup Completed for User: %s", userID)
			points.AddPointsWithEvent(userID, 15, "Device Backup Completed")
		}
	}
}

func dispatchMultiplayerNotifications(e Entity) {
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
