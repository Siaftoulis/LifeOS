package system

import (
	"encoding/json"
	"fmt"
	"time"
)

type PresetItem struct {
	Name       string                 `json:"name"`
	PresetData map[string]interface{} `json:"data"`
	UpdatedAt  int64                  `json:"updated_at"`
}

func GetAllPresets() (map[string]interface{}, error) {
	if DB == nil {
		return nil, fmt.Errorf("system DB not initialized")
	}

	rows, err := DB.Query("SELECT name, preset_json, updated_at FROM user_presets ORDER BY updated_at DESC")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	presets := make(map[string]interface{})
	for rows.Next() {
		var name, rawJson string
		var updatedAt int64
		if err := rows.Scan(&name, &rawJson, &updatedAt); err != nil {
			continue
		}

		var parsed map[string]interface{}
		if err := json.Unmarshal([]byte(rawJson), &parsed); err == nil {
			presets[name] = parsed
		}
	}

	return presets, nil
}

func SavePreset(name string, data map[string]interface{}) error {
	if DB == nil {
		return fmt.Errorf("system DB not initialized")
	}

	rawBytes, err := json.Marshal(data)
	if err != nil {
		return fmt.Errorf("invalid preset data: %v", err)
	}

	now := time.Now().Unix()
	_, err = DB.Exec(`
		INSERT INTO user_presets (name, preset_json, updated_at) 
		VALUES (?, ?, ?) 
		ON CONFLICT(name) DO UPDATE SET 
			preset_json = excluded.preset_json, 
			updated_at = excluded.updated_at
	`, name, string(rawBytes), now)

	return err
}

func DeletePreset(name string) error {
	if DB == nil {
		return fmt.Errorf("system DB not initialized")
	}

	_, err := DB.Exec("DELETE FROM user_presets WHERE name = ?", name)
	return err
}
