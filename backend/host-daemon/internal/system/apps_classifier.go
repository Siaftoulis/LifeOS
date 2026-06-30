package system

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

type AppItem struct {
	PackageName string `json:"package_name"`
	Name        string `json:"name"`
}

type CategorizeRequest struct {
	Apps []AppItem `json:"apps"`
}

func classifyAppHeuristically(packageName, name string) string {
	pkg := strings.ToLower(packageName)
	appName := strings.ToLower(name)

	// 1. Games
	if strings.Contains(pkg, "game") ||
		strings.Contains(pkg, "gaming") ||
		strings.Contains(pkg, "arcade") ||
		strings.Contains(pkg, "puzzle") ||
		strings.Contains(pkg, "sport") ||
		strings.Contains(pkg, "play.games") ||
		strings.Contains(pkg, "xbox") ||
		strings.Contains(pkg, "playstation") ||
		strings.Contains(pkg, "steam") ||
		strings.Contains(pkg, "retroarch") ||
		strings.Contains(appName, "game") ||
		strings.Contains(appName, "toy") {
		if !strings.Contains(pkg, "vending") && !strings.Contains(pkg, "play.services") {
			return "Games"
		}
	}

	// 2. Photographs
	if strings.Contains(pkg, "camera") ||
		strings.Contains(pkg, "gallery") ||
		strings.Contains(pkg, "photo") ||
		strings.Contains(pkg, "image") ||
		strings.Contains(pkg, "paint") ||
		strings.Contains(pkg, "draw") ||
		strings.Contains(pkg, "sketch") ||
		strings.Contains(pkg, "photograph") ||
		strings.Contains(pkg, "picture") ||
		strings.Contains(pkg, "lens") ||
		strings.Contains(pkg, "snapseed") ||
		strings.Contains(pkg, "photoshop") ||
		strings.Contains(pkg, "gopro") ||
		strings.Contains(appName, "camera") ||
		strings.Contains(appName, "photo") ||
		strings.Contains(appName, "gallery") ||
		strings.Contains(appName, "picture") {
		return "Photographs"
	}

	// 3. Google Archives
	if strings.Contains(pkg, "com.google") ||
		strings.Contains(pkg, "google.android") ||
		strings.Contains(pkg, "chrome") ||
		strings.Contains(pkg, "youtube") ||
		strings.Contains(pkg, "gmail") ||
		strings.Contains(pkg, "vending") ||
		strings.Contains(pkg, "com.google.android.gm") ||
		strings.Contains(appName, "google") ||
		strings.Contains(appName, "chrome") ||
		strings.Contains(appName, "youtube") ||
		strings.Contains(appName, "gmail") ||
		strings.Contains(appName, "drive") ||
		strings.Contains(appName, "hangouts") ||
		strings.Contains(appName, "sheets") ||
		strings.Contains(appName, "docs") ||
		strings.Contains(appName, "slides") ||
		strings.Contains(appName, "meet") ||
		strings.Contains(appName, "duo") {
		return "Google Archives"
	}

	return "Everything Else"
}

func classifyAppsWithGemini(apiKey string, apps []AppItem) (map[string]string, error) {
	appsJson, err := json.Marshal(apps)
	if err != nil {
		return nil, err
	}

	prompt := fmt.Sprintf(`You are an Android application categorizer. 
Classify each app from the provided list into exactly one of these categories:
"Games", "Photographs", "Google Archives", "Everything Else".

Definitions:
- "Games": Video games, gaming platforms, and game utilities.
- "Photographs": Camera apps, galleries, image editors, photo sharing, and drawing apps.
- "Google Archives": Apps made by Google EXCEPT if they are games or galleries.
- "Everything Else": Standard utility apps, social networks, messaging/chat apps, note-taking apps, music players, tools, and everything else.

Return ONLY a flat JSON object where the key is the "package_name" and the value is the exact category name. Do not include markdown formatting or code blocks.

List to classify:
%s`, string(appsJson))

	reqPayload := map[string]interface{}{
		"contents": []map[string]interface{}{
			{
				"parts": []map[string]interface{}{
					{"text": prompt},
				},
			},
		},
	}

	reqBody, err := json.Marshal(reqPayload)
	if err != nil {
		return nil, err
	}

	url := fmt.Sprintf("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=%s", apiKey)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Post(url, "application/json", bytes.NewBuffer(reqBody))
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("Gemini API returned status %d: %s", resp.StatusCode, string(bodyBytes))
	}

	var geminiResp struct {
		Candidates []struct {
			Content struct {
				Parts []struct {
					Text string `json:"text"`
				} `json:"parts"`
			} `json:"content"`
		} `json:"candidates"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&geminiResp); err != nil {
		return nil, err
	}

	if len(geminiResp.Candidates) == 0 || len(geminiResp.Candidates[0].Content.Parts) == 0 {
		return nil, fmt.Errorf("empty response from Gemini")
	}

	rawText := geminiResp.Candidates[0].Content.Parts[0].Text
	rawText = strings.TrimSpace(rawText)

	if strings.HasPrefix(rawText, "```json") {
		rawText = strings.TrimPrefix(rawText, "```json")
		rawText = strings.TrimSuffix(rawText, "```")
	} else if strings.HasPrefix(rawText, "```") {
		rawText = strings.TrimPrefix(rawText, "```")
		rawText = strings.TrimSuffix(rawText, "```")
	}
	rawText = strings.TrimSpace(rawText)

	var result map[string]string
	if err := json.Unmarshal([]byte(rawText), &result); err != nil {
		return nil, fmt.Errorf("failed to parse Gemini response text as JSON: %s. Error: %v", rawText, err)
	}

	return result, nil
}
