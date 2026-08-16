package automations

import (
	"time"

	"lifeos/host-daemon/internal/bus"
	"lifeos/host-daemon/internal/engine"
	"lifeos/host-daemon/internal/points"
)

// engineRules keeps every legacy General-Engine award alive as a bus rule,
// so the rules survive the engine module itself (retired in Workstream C).
func engineRules() {
	bus.Subscribe("engine:upsert:"+string(engine.TypeEvent), func(e bus.Event) {
		if ent, ok := e.Payload.(engine.Entity); ok {
			engine.DispatchNotifications(ent)
		}
	})

	bus.Subscribe("engine:upsert:"+string(engine.TypeTask), func(e bus.Event) {
		ent, ok := e.Payload.(engine.Entity)
		if !ok {
			return
		}
		userID := engineUser(ent)
		engine.DispatchNotifications(ent)
		if status, _ := ent.Payload["status"].(string); status == "completed" {
			points.AddPointsWithEvent(userID, 15, "Completed Task: "+ent.ID)
		}
	})

	bus.Subscribe("engine:upsert:"+string(engine.TypeHabit), func(e bus.Event) {
		ent, ok := e.Payload.(engine.Entity)
		if !ok {
			return
		}
		if status, _ := ent.Payload["status"].(string); status == "completed" {
			points.AddPointsWithEvent(engineUser(ent), 10, "Completed Habit")
		}
	})

	bus.Subscribe("engine:upsert:"+string(engine.TypeZenLog), func(e bus.Event) {
		if ent, ok := e.Payload.(engine.Entity); ok {
			points.AddPointsWithEvent(engineUser(ent), 20, "Wrote Daily Zen Log")
		}
	})

	bus.Subscribe("engine:upsert:"+string(engine.TypeMetric), func(e bus.Event) {
		ent, ok := e.Payload.(engine.Entity)
		if !ok {
			return
		}
		userID := engineUser(ent)
		metricType, _ := ent.Payload["metric_type"].(string)
		val, _ := ent.Payload["value"].(float64)
		if val == 0 {
			if intVal, ok := ent.Payload["value"].(int); ok {
				val = float64(intVal)
			}
		}

		now := time.Now()
		if metricType == "steps" && val >= 10000 {
			engine.SaveEntity(autoGoal(engine.TypeTask, "auto_task_steps_"+now.Format("20060102"), userID,
				"🤖 Completed Daily 10k Steps Goal", 25, now))
			points.AddPointsWithEvent(userID, 25, "Achieved Daily 10k Steps Goal")
		} else if metricType == "water" && val >= 2.0 {
			engine.SaveEntity(autoGoal(engine.TypeTask, "auto_task_water_"+now.Format("20060102"), userID,
				"🤖 Hydration Goal (2L Water)", 15, now))
			points.AddPointsWithEvent(userID, 15, "Achieved Daily 2L Water Goal")
		} else if metricType == "sleep" && val >= 7.5 {
			engine.SaveEntity(autoGoal(engine.TypeTask, "auto_task_sleep_"+now.Format("20060102"), userID,
				"🤖 Optimal Sleep Goal (7.5h)", 20, now))
			points.AddPointsWithEvent(userID, 20, "Achieved Daily Sleep Goal")
		}
	})

	bus.Subscribe("engine:upsert:"+string(engine.TypeFlashcardReview), func(e bus.Event) {
		ent, ok := e.Payload.(engine.Entity)
		if !ok {
			return
		}
		rating, _ := ent.Payload["rating"].(float64)
		if rating >= 3 {
			points.AddPointsWithEvent(engineUser(ent), 5, "Flashcard Spaced-Repetition Success")
		}
	})

	for _, mediaType := range []engine.EntityType{engine.TypeMediaMovie, engine.TypeYoutubeVideo} {
		bus.Subscribe("engine:upsert:"+string(mediaType), func(e bus.Event) {
			ent, ok := e.Payload.(engine.Entity)
			if !ok {
				return
			}
			if status, _ := ent.Payload["status"].(string); status == "watched" {
				points.AddPointsWithEvent(engineUser(ent), 10, "Media Watchlist Completion")
			}
		})
	}

	bus.Subscribe("engine:upsert:"+string(engine.TypeGeofence), func(e bus.Event) {
		ent, ok := e.Payload.(engine.Entity)
		if !ok {
			return
		}
		event, _ := ent.Payload["event"].(string)
		locationName, _ := ent.Payload["name"].(string)
		if event == "enter" && (locationName == "Gym" || locationName == "Fitness") {
			points.AddPointsWithEvent(engineUser(ent), 15, "Gym Geofence Arrival")
		}
	})

	bus.Subscribe("engine:upsert:"+string(engine.TypeCloudBackup), func(e bus.Event) {
		ent, ok := e.Payload.(engine.Entity)
		if !ok {
			return
		}
		if status, _ := ent.Payload["status"].(string); status == "completed" {
			points.AddPointsWithEvent(engineUser(ent), 15, "Device Backup Completed")
		}
	})

	// Finance Hub: logging money and paying bills earns stars. The rule marks
	// the entity awarded (and re-saves it) so repeat upserts of the same
	// entity — client re-polls and re-saves — don't re-award. The daily cap
	// backstops rapid-fire abuse either way.
	bus.Subscribe("engine:upsert:"+string(engine.TypeBill), func(e bus.Event) {
		ent, ok := e.Payload.(engine.Entity)
		if !ok || ent.Payload["points_awarded"] == true {
			return
		}
		if paid, _ := ent.Payload["paid"].(bool); paid {
			ent.Payload["points_awarded"] = true
			engine.SaveEntity(ent)
			name, _ := ent.Payload["name"].(string)
			points.AddPointsWithEvent(engineUser(ent), 20, "Paid Monthly Bill: "+name)
		}
	})

	bus.Subscribe("engine:upsert:"+string(engine.TypeBankTransaction), func(e bus.Event) {
		ent, ok := e.Payload.(engine.Entity)
		if !ok || ent.Payload["points_awarded"] == true {
			return
		}
		ent.Payload["points_awarded"] = true
		engine.SaveEntity(ent)
		txType, _ := ent.Payload["type"].(string)
		if txType == "income" {
			points.AddPointsWithEvent(engineUser(ent), 10, "Recorded Income")
		} else {
			points.AddPointsWithEvent(engineUser(ent), 5, "Logged Expense")
		}
	})

	bus.Subscribe("engine:upsert:"+string(engine.TypeBudgetConfig), func(e bus.Event) {
		ent, ok := e.Payload.(engine.Entity)
		if !ok || ent.Payload["points_awarded"] == true {
			return
		}
		ent.Payload["points_awarded"] = true
		engine.SaveEntity(ent)
		points.AddPointsWithEvent(engineUser(ent), 15, "Set Monthly Budget")
	})
}

// engineUser falls back to the legacy default when an entity has no creator.
func engineUser(e engine.Entity) string {
	if e.CreatorID != "" {
		return e.CreatorID
	}
	return "panospds" // ponytail: legacy default; multi-user mapping arrives with real auth
}

func autoGoal(t engine.EntityType, id, userID, title string, baseXP int, now time.Time) engine.Entity {
	return engine.Entity{
		ID:        id,
		Type:      t,
		CreatorID: userID,
		Payload: map[string]interface{}{
			"title":    title,
			"status":   "completed",
			"base_xp":  baseXP,
			"due_date": now.Format(time.RFC3339),
		},
		CreatedAt: now,
		UpdatedAt: now,
	}
}