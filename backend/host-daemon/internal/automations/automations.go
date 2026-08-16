// Package automations is the only place in the repo where domains meet.
// Every ecosystem rule lives here as a bus subscription: publishers just
// announce facts, this package decides what happens next. The bus keeps all
// other packages decoupled from each other.
package automations

import (
	"bytes"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"sync"

	"lifeos/host-daemon/internal/bus"
	"lifeos/host-daemon/internal/books"
	"lifeos/host-daemon/internal/location"
	"lifeos/host-daemon/internal/movies"
	"lifeos/host-daemon/internal/player"
	"lifeos/host-daemon/internal/points"
)

var registerOnce sync.Once

// Register wires all ecosystem rules. Called once from main.go.
func Register() {
	registerOnce.Do(register)
}

func register() {
	// location:enter → physical-world webhook (Home Assistant or any endpoint)
	bus.Subscribe("location:enter", func(e bus.Event) {
		entered, ok := e.Payload.(location.LocationEnterEvent)
		if !ok {
			return
		}
		for _, f := range entered.Fences {
			log.Printf("[automation] user %s entered zone %q → webhook", entered.DeviceID, f.Name)
			fireWebhook(location.WebhookPayload{Event: "zone_entered", DeviceID: entered.DeviceID, Zone: f.Name})
		}
	})

	// points:negative-balance → appliance/TV lock webhook
	bus.Subscribe("points:negative-balance", func(e bus.Event) {
		change, ok := e.Payload.(points.ChangeEvent)
		if !ok {
			return
		}
		log.Printf("[automation] TV lock: user %s balance %d (%s)", change.UserID, change.Balance, change.Event)
		fireWebhook(map[string]any{
			"event":   "tv_lock",
			"user_id": change.UserID,
			"balance": change.Balance,
			"reason":  change.Event,
		})
	})

	// rpg:task-complete → telemetry (awards already applied by the player)
	bus.Subscribe("rpg:task-complete", func(e bus.Event) {
		if c, ok := e.Payload.(player.TaskCompleteEvent); ok {
			log.Printf("[automation] task %s complete: %+d XP, %+d points (%s)", c.TaskID, c.XP, c.Points, c.Attribute)
		}
	})

	// movies:watched → +10 points
	bus.Subscribe("movies:watched", func(e bus.Event) {
		if m, ok := e.Payload.(movies.WatchedEvent); ok && m.UserID != "" {
			points.AddPointsWithEvent(m.UserID, 10, "Watched movie: "+m.Title)
		}
	})

	// books:finished → +30 points
	bus.Subscribe("books:finished", func(e bus.Event) {
		if b, ok := e.Payload.(books.FinishedEvent); ok && b.UserID != "" {
			points.AddPointsWithEvent(b.UserID, 30, "Finished book: "+b.BookID)
		}
	})

	engineRules()
}

// fireWebhook targets Home Assistant (or any HTTP endpoint) — the physical
// world side of the ecosystem.
func fireWebhook(payload any) {
	webhookURL := os.Getenv("AUTOMATION_WEBHOOK_URL")
	if webhookURL == "" {
		webhookURL = "http://localhost:8123/api/webhook/lifeos"
	}
	data, err := json.Marshal(payload)
	if err != nil {
		return
	}
	go func() {
		if _, err := http.Post(webhookURL, "application/json", bytes.NewBuffer(data)); err != nil {
			log.Printf("[automation] webhook failed: %v", err)
		}
	}()
}