package system

import (
	"encoding/json"
	"os"
)

type Setting struct {
	Key       string `json:"key"`
	Value     string `json:"value"`
	UpdatedAt int64  `json:"updated_at"`
}

var settingsFile = "./data/system_settings.json"

func loadSettings() ([]Setting, error) {
	if _, err := os.Stat(settingsFile); os.IsNotExist(err) {
		return []Setting{}, nil
	}
	data, err := os.ReadFile(settingsFile)
	if err != nil {
		return nil, err
	}
	var settings []Setting
	if err := json.Unmarshal(data, &settings); err != nil {
		return nil, err
	}
	return settings, nil
}

func saveSettings(settings []Setting) error {
	_ = os.MkdirAll("./data", 0755)
	data, err := json.MarshalIndent(settings, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(settingsFile, data, 0644)
}
