package music

import (
	"context"
	"encoding/json"
	"net/http"
	"strings"
	"time"
)

type MusicSettingsPayload struct {
	SlskdURL     string `json:"slskd_url"`
	SlskdAPIKey  string `json:"slskd_api_key"`
	SlskdEnabled string `json:"slskd_enabled"`
	TidalToken   string `json:"tidal_token"`
	DeezerARL    string `json:"deezer_arl"`
}

// HandleGetConfig handles GET /api/v1/music/config
func HandleGetConfig(w http.ResponseWriter, r *http.Request) {
	cfg := GetAllMusicConfig()

	// Provide sensible defaults if not set
	slskdURL := cfg["slskd_url"]
	if slskdURL == "" {
		slskdURL = "http://localhost:5030"
	}
	slskdEnabled := cfg["slskd_enabled"]
	if slskdEnabled == "" {
		slskdEnabled = "true"
	}

	res := MusicSettingsPayload{
		SlskdURL:     slskdURL,
		SlskdAPIKey:  cfg["slskd_api_key"],
		SlskdEnabled: slskdEnabled,
		TidalToken:   cfg["tidal_token"],
		DeezerARL:    cfg["deezer_arl"],
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(res)
}

// HandleSaveConfig handles POST /api/v1/music/config
func HandleSaveConfig(w http.ResponseWriter, r *http.Request) {
	var payload MusicSettingsPayload
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		http.Error(w, "invalid json payload", http.StatusBadRequest)
		return
	}

	if payload.SlskdURL != "" {
		_ = SetMusicConfig("slskd_url", strings.TrimRight(payload.SlskdURL, "/"))
	}
	_ = SetMusicConfig("slskd_api_key", payload.SlskdAPIKey)
	if payload.SlskdEnabled != "" {
		_ = SetMusicConfig("slskd_enabled", payload.SlskdEnabled)
	}
	_ = SetMusicConfig("tidal_token", payload.TidalToken)
	_ = SetMusicConfig("deezer_arl", payload.DeezerARL)

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]string{
		"status":  "ok",
		"message": "Music settings updated successfully",
	})
}

// HandleTestSlskd handles POST /api/v1/music/config/test-slskd
func HandleTestSlskd(w http.ResponseWriter, r *http.Request) {
	var payload struct {
		URL    string `json:"url"`
		APIKey string `json:"api_key"`
	}
	_ = json.NewDecoder(r.Body).Decode(&payload)

	testURL := payload.URL
	if testURL == "" {
		testURL = GetMusicConfig("slskd_url")
	}
	if testURL == "" {
		testURL = "http://localhost:5030"
	}

	client := &SlskdClient{
		BaseURL:    strings.TrimRight(testURL, "/"),
		APIKey:     payload.APIKey,
		HTTPClient: &http.Client{Timeout: 1500 * time.Millisecond},
	}

	ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
	defer cancel()

	available := client.IsAvailable(ctx)
	w.Header().Set("Content-Type", "application/json")
	if available {
		_ = json.NewEncoder(w).Encode(map[string]interface{}{
			"status":    "ok",
			"available": true,
			"url":       client.BaseURL,
			"message":   "Successfully connected to Soulseek (slskd) daemon",
		})
	} else {
		_ = json.NewEncoder(w).Encode(map[string]interface{}{
			"status":    "error",
			"available": false,
			"url":       client.BaseURL,
			"message":   "Could not connect to slskd at " + client.BaseURL + ". Make sure slskd is running.",
		})
	}
}
