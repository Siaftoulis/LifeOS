package main

import (
	"log"
	"net/http"
	"time"
)

// The URL of your Custom API (Cloudflare Worker)
const customDDNSApiUrl = "https://your-worker-name.your-cloudflare-subdomain.workers.dev/update"
const customDDNSAuthToken = "Bearer lifeos_super_secret_token_123"

func startCustomDDNSUpdater() {
	for {
		err := updateCustomDDNS()
		if err != nil {
			log.Printf("Failed to update Custom DDNS: %v", err)
		} else {
			log.Printf("Successfully updated Custom DDNS IP")
		}
		
		// Wait 10 minutes before the next update
		time.Sleep(10 * time.Minute)
	}
}

func updateCustomDDNS() error {
	req, err := http.NewRequest("POST", customDDNSApiUrl, nil)
	if err != nil {
		return err
	}
	
	req.Header.Set("Authorization", customDDNSAuthToken)
	
	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	
	if resp.StatusCode != http.StatusOK {
		log.Printf("Custom DDNS API returned status: %d", resp.StatusCode)
	}
	
	return nil
}
