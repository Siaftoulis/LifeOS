package location

import (
	"log"
)

// TriggerAutomation hooks into home management or other backend systems
func TriggerAutomation(report LocationReport, fences []TriggeredGeofence) {
	for _, f := range fences {
		log.Printf("[AUTOMATION] User %s entered zone '%s'", report.DeviceID, f.Name)
		
		if f.Name == "Work Polygon" {
			log.Printf("[AUTOMATION] Executing: Starting robot vacuums at home since user went to work.")
			// In the future: hit home assistant API or run internal scripts
		}
		
		if f.Name == "Home Base" {
			log.Printf("[AUTOMATION] Executing: Turning on AC and lights.")
		}
	}
}
