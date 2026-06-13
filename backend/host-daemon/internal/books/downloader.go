package books

import (
	"log"
)

// TriggerVPNScrape acts as a background hook executing search commands over Tailscale or local VPN.
func TriggerVPNScrape(query string) {
	log.Printf("VPN Scrape triggered for query: %s", query)
}
