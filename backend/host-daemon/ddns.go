package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
)

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
	apiUrl := os.Getenv("DDNS_API_URL")
	authToken := os.Getenv("DDNS_AUTH_TOKEN")
	if apiUrl == "" {
		return fmt.Errorf("DDNS_API_URL environment variable is not set")
	}

	req, err := http.NewRequest("POST", apiUrl, nil)
	if err != nil {
		return err
	}

	if authToken != "" {
		req.Header.Set("Authorization", authToken)
	}

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("Custom DDNS API returned status: %d", resp.StatusCode)
	}

	return nil
}
