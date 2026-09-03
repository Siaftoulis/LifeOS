package main

import (
	"encoding/json"
	"fmt"
	"os"
	"time"

	"lifeos/host-daemon/internal/prayers"
)

func main() {
	now := time.Now()
	serviceIDs := []string{
		"divine_liturgy_chrysostom",
		"divine_liturgy_basil",
		"matins",
		"vespers",
		"midnight_office",
		"hour_first",
		"hour_third",
		"hour_sixth",
		"hour_ninth",
		"morning_prayer",
		"small_compline",
		"great_compline",
		"communion_prep",
		"communion_thanks",
		"paraklesis_small",
		"paraklesis_great",
		"akathist_hymn",
		"paraklesis_st_nektarios",
		"paraklesis_st_paisios",
		"paraklesis_st_fanourios",
		"service_artoklasia_litany",
		"jesus_prayer",
		"ephraim_prayer",
		"table_prayers",
		"optina_prayer",
	}

	result := make(map[string]*prayers.PrayerService)

	for _, id := range serviceIDs {
		svc, err := prayers.BuildService(id, now)
		if err != nil {
			fmt.Printf("Warning: error building service %s: %v\n", id, err)
			continue
		}
		result[id] = svc
		fmt.Printf("Built %s: %s (%d sections)\n", id, svc.Title, len(svc.Sections))
	}

	// Add common aliases so any caller finds the service
	if chrysostom, ok := result["divine_liturgy_chrysostom"]; ok {
		result["divine_liturgy"] = chrysostom
	}
	if smallParaklesis, ok := result["paraklesis_small"]; ok {
		result["paraklesis"] = smallParaklesis
	}
	if h1, ok := result["hour_first"]; ok {
		result["first_hour"] = h1
	}
	if h3, ok := result["hour_third"]; ok {
		result["third_hour"] = h3
	}
	if h6, ok := result["hour_sixth"]; ok {
		result["sixth_hour"] = h6
	}
	if h9, ok := result["hour_ninth"]; ok {
		result["ninth_hour"] = h9
	}
	if mp, ok := result["morning_prayer"]; ok {
		result["morning_prayers"] = mp
	}
	if cp, ok := result["communion_prep"]; ok {
		result["communion_canon"] = cp
	}

	data, err := json.MarshalIndent(result, "", "  ")
	if err != nil {
		fmt.Printf("Error marshaling JSON: %v\n", err)
		os.Exit(1)
	}

	outPath := "../../client/assets/prayers_core.json"
	err = os.WriteFile(outPath, data, 0644)
	if err != nil {
		fmt.Printf("Error writing file %s: %v\n", outPath, err)
		os.Exit(1)
	}

	fmt.Printf("\nSUCCESS! Exported %d services to %s (%d KB)\n", len(result), outPath, len(data)/1024)
}
