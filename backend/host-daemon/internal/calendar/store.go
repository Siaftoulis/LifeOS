package calendar

import (
	"encoding/json"
	"log"
	"os"
	"sync"
)

type CalendarEvent struct {
	ID        string `json:"id"`
	Title     string `json:"title"`
	StartTime int64  `json:"start_time"`
	EndTime   int64  `json:"end_time"`
	Type      string `json:"type"`
}

var (
	eventLock sync.RWMutex
	events    []CalendarEvent
	eventFile = "./data/calendar.json"
)

func init() {
	events = make([]CalendarEvent, 0)
	loadEvents()
}

func loadEvents() {
	eventLock.Lock()
	defer eventLock.Unlock()

	data, err := os.ReadFile(eventFile)
	if err != nil {
		if os.IsNotExist(err) {
			os.MkdirAll("./data", 0755)
			saveEvents()
			return
		}
		log.Printf("Error reading calendar.json: %v", err)
		return
	}

	if err := json.Unmarshal(data, &events); err != nil {
		log.Printf("Error parsing calendar.json: %v", err)
	}
}

func saveEvents() {
	data, err := json.MarshalIndent(events, "", "  ")
	if err != nil {
		log.Printf("Error marshaling events: %v", err)
		return
	}

	if err := os.WriteFile(eventFile, data, 0644); err != nil {
		log.Printf("Error writing calendar.json: %v", err)
	}
}

func GetEvents() []CalendarEvent {
	eventLock.RLock()
	defer eventLock.RUnlock()
	return events
}

func CreateEvent(event CalendarEvent) {
	eventLock.Lock()
	defer eventLock.Unlock()
	events = append(events, event)
	saveEvents()
}
