package music

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"
)

var innerTubeHTTPClient = &http.Client{
	Timeout: 10 * time.Second,
}

// SearchInnerTube executes a direct HTTP InnerTube WEB_REMIX search against YouTube Music,
// parsing responsive list items and card shelves with sub-second latency and zero CLI processes.
func SearchInnerTube(ctx context.Context, query string) ([]SearchResult, error) {
	query = strings.TrimSpace(query)
	if query == "" {
		return []SearchResult{}, nil
	}

	payload := map[string]any{
		"context": map[string]any{
			"client": map[string]any{
				"clientName":    "WEB_REMIX",
				"clientVersion": "1.20240101.01.00",
				"hl":            "en",
				"gl":            "US",
			},
		},
		"query": query,
	}

	bodyBytes, err := json.Marshal(payload)
	if err != nil {
		return nil, fmt.Errorf("marshal search payload: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, "https://music.youtube.com/youtubei/v1/search?prettyPrint=false", bytes.NewReader(bodyBytes))
	if err != nil {
		return nil, fmt.Errorf("create search request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) Gecko/20100101 Firefox/128.0")
	req.Header.Set("Referer", "https://music.youtube.com/")
	req.Header.Set("Origin", "https://music.youtube.com")

	resp, err := innerTubeHTTPClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("innertube search request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("innertube search returned status %d", resp.StatusCode)
	}

	respData, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("read innertube response: %w", err)
	}

	var root map[string]any
	if err := json.Unmarshal(respData, &root); err != nil {
		return nil, fmt.Errorf("unmarshal innertube response: %w", err)
	}

	results := parseInnerTubeSearchResults(root)
	return results, nil
}

func parseInnerTubeSearchResults(root map[string]any) []SearchResult {
	var results []SearchResult
	seen := make(map[string]bool)

	contents, ok := root["contents"].(map[string]any)
	if !ok {
		return results
	}
	tabbed, ok := contents["tabbedSearchResultsRenderer"].(map[string]any)
	if !ok {
		return results
	}
	tabs, ok := tabbed["tabs"].([]any)
	if !ok || len(tabs) == 0 {
		return results
	}
	tab0, ok := tabs[0].(map[string]any)["tabRenderer"].(map[string]any)
	if !ok {
		return results
	}
	tabContent, ok := tab0["content"].(map[string]any)
	if !ok {
		return results
	}
	sectionList, ok := tabContent["sectionListRenderer"].(map[string]any)
	if !ok {
		return results
	}
	secContents, ok := sectionList["contents"].([]any)
	if !ok {
		return results
	}

	for _, sec := range secContents {
		secMap, ok := sec.(map[string]any)
		if !ok {
			continue
		}

		// 1. Top card shelf (e.g. direct hit)
		if card, ok := secMap["musicCardShelfRenderer"].(map[string]any); ok {
			track := parseCardShelf(card)
			if track.ID != "" && !seen[track.ID] {
				seen[track.ID] = true
				results = append(results, track)
			}
		}

		// 2. Sections containing musicResponsiveListItemRenderer
		var listItems []any
		if itemSec, ok := secMap["itemSectionRenderer"].(map[string]any); ok {
			if itms, ok := itemSec["contents"].([]any); ok {
				listItems = itms
			}
		} else if shelf, ok := secMap["musicShelfRenderer"].(map[string]any); ok {
			if itms, ok := shelf["contents"].([]any); ok {
				listItems = itms
			}
		}

		for _, itm := range listItems {
			itmMap, ok := itm.(map[string]any)
			if !ok {
				continue
			}
			renderer, ok := itmMap["musicResponsiveListItemRenderer"].(map[string]any)
			if !ok {
				continue
			}
			track := parseResponsiveListItem(renderer)
			if track.ID != "" && track.Title != "" && !seen[track.ID] {
				seen[track.ID] = true
				results = append(results, track)
			}
		}
	}

	return results
}

func parseCardShelf(card map[string]any) SearchResult {
	var track SearchResult

	// Title & VideoID from title runs
	if titleObj, ok := card["title"].(map[string]any); ok {
		if runs, ok := titleObj["runs"].([]any); ok && len(runs) > 0 {
			if r0, ok := runs[0].(map[string]any); ok {
				track.Title, _ = r0["text"].(string)
				if nav, ok := r0["navigationEndpoint"].(map[string]any); ok {
					if watch, ok := nav["watchEndpoint"].(map[string]any); ok {
						track.ID, _ = watch["videoId"].(string)
					}
				}
			}
		}
	}

	// Subtitle runs: Artist, Album, Duration
	if subObj, ok := card["subtitle"].(map[string]any); ok {
		if runs, ok := subObj["runs"].([]any); ok {
			var artistParts []string
			for _, r := range runs {
				rMap, ok := r.(map[string]any)
				if !ok {
					continue
				}
				txt, _ := rMap["text"].(string)
				txt = strings.TrimSpace(txt)
				if txt == "" || txt == "•" || strings.EqualFold(txt, "Song") || strings.EqualFold(txt, "Video") {
					continue
				}
				if strings.Contains(txt, ":") && isDurationString(txt) {
					track.Duration = parseDurationString(txt)
					continue
				}
				artistParts = append(artistParts, txt)
			}
			if len(artistParts) > 0 {
				track.Artist = strings.Join(artistParts, " ")
			}
		}
	}

	// Thumbnail
	if thumbObj, ok := card["thumbnail"].(map[string]any); ok {
		track.Thumbnail = extractThumbnailFromObj(thumbObj, track.ID)
	}

	return track
}

func parseResponsiveListItem(renderer map[string]any) SearchResult {
	var track SearchResult

	// Extract Video ID
	if pl, ok := renderer["playlistItemData"].(map[string]any); ok {
		track.ID, _ = pl["videoId"].(string)
	}
	if track.ID == "" {
		if nav, ok := renderer["navigationEndpoint"].(map[string]any); ok {
			if watch, ok := nav["watchEndpoint"].(map[string]any); ok {
				track.ID, _ = watch["videoId"].(string)
			}
		}
	}

	// Flex Columns
	flexCols, _ := renderer["flexColumns"].([]any)
	if len(flexCols) > 0 {
		if col0, ok := flexCols[0].(map[string]any)["musicResponsiveListItemFlexColumnRenderer"].(map[string]any); ok {
			track.Title = extractRunsText(col0["text"])
			if track.ID == "" {
				// Try navigation endpoint inside run
				if runs, ok := col0["text"].(map[string]any)["runs"].([]any); ok && len(runs) > 0 {
					if r0, ok := runs[0].(map[string]any); ok {
						if nav, ok := r0["navigationEndpoint"].(map[string]any); ok {
							if watch, ok := nav["watchEndpoint"].(map[string]any); ok {
								track.ID, _ = watch["videoId"].(string)
							}
						}
					}
				}
			}
		}
	}

	if len(flexCols) > 1 {
		if col1, ok := flexCols[1].(map[string]any)["musicResponsiveListItemFlexColumnRenderer"].(map[string]any); ok {
			if runs, ok := col1["text"].(map[string]any)["runs"].([]any); ok {
				var artistParts []string
				for _, r := range runs {
					rMap, ok := r.(map[string]any)
					if !ok {
						continue
					}
					txt, _ := rMap["text"].(string)
					txtTrimmed := strings.TrimSpace(txt)
					if txtTrimmed == "" || txtTrimmed == "•" || strings.EqualFold(txtTrimmed, "Song") || strings.EqualFold(txtTrimmed, "Video") {
						continue
					}
					if strings.Contains(txtTrimmed, ":") && isDurationString(txtTrimmed) {
						track.Duration = parseDurationString(txtTrimmed)
						continue
					}
					// Only append non-delimiter tokens or cleanly formatted names
					if txt != " • " {
						artistParts = append(artistParts, txt)
					}
				}
				if len(artistParts) > 0 {
					track.Artist = strings.TrimSpace(strings.Join(artistParts, ""))
				}
			}
		}
	}

	// Check fixedColumns for Duration if not yet found
	if track.Duration == 0 {
		if fixedCols, ok := renderer["fixedColumns"].([]any); ok {
			for _, fc := range fixedCols {
				if col, ok := fc.(map[string]any)["musicResponsiveListItemFixedColumnRenderer"].(map[string]any); ok {
					txt := extractRunsText(col["text"])
					if isDurationString(txt) {
						track.Duration = parseDurationString(txt)
						break
					}
				}
			}
		}
	}

	// Thumbnail
	if thumbObj, ok := renderer["thumbnail"].(map[string]any); ok {
		track.Thumbnail = extractThumbnailFromObj(thumbObj, track.ID)
	}
	if track.Thumbnail == "" && track.ID != "" {
		track.Thumbnail = "https://i.ytimg.com/vi/" + track.ID + "/hqdefault.jpg"
	}

	return track
}

func extractRunsText(v any) string {
	m, ok := v.(map[string]any)
	if !ok {
		return ""
	}
	runs, ok := m["runs"].([]any)
	if !ok {
		return ""
	}
	var sb strings.Builder
	for _, r := range runs {
		if rMap, ok := r.(map[string]any); ok {
			if t, ok := rMap["text"].(string); ok {
				sb.WriteString(t)
			}
		}
	}
	return sb.String()
}

func extractThumbnailFromObj(thumbObj map[string]any, id string) string {
	var thumbs []any
	if musicThumb, ok := thumbObj["musicThumbnailRenderer"].(map[string]any); ok {
		if tObj, ok := musicThumb["thumbnail"].(map[string]any); ok {
			thumbs, _ = tObj["thumbnails"].([]any)
		}
	} else if tObj, ok := thumbObj["thumbnail"].(map[string]any); ok {
		thumbs, _ = tObj["thumbnails"].([]any)
	}

	if len(thumbs) > 0 {
		last := thumbs[len(thumbs)-1].(map[string]any)
		if u, ok := last["url"].(string); ok && u != "" {
			return u
		}
	}
	if id != "" {
		return "https://i.ytimg.com/vi/" + id + "/hqdefault.jpg"
	}
	return ""
}

func isDurationString(s string) bool {
	s = strings.TrimSpace(s)
	parts := strings.Split(s, ":")
	if len(parts) < 2 || len(parts) > 3 {
		return false
	}
	for _, p := range parts {
		if _, err := strconv.Atoi(p); err != nil {
			return false
		}
	}
	return true
}

func parseDurationString(s string) float64 {
	parts := strings.Split(strings.TrimSpace(s), ":")
	if len(parts) == 2 {
		m, _ := strconv.ParseFloat(parts[0], 64)
		sec, _ := strconv.ParseFloat(parts[1], 64)
		return m*60 + sec
	} else if len(parts) == 3 {
		h, _ := strconv.ParseFloat(parts[0], 64)
		m, _ := strconv.ParseFloat(parts[1], 64)
		sec, _ := strconv.ParseFloat(parts[2], 64)
		return h*3600 + m*60 + sec
	}
	return 0
}
