package prayers

import (
	"testing"
	"time"
)

func TestCalculateOrthodoxEaster(t *testing.T) {
	// Orthodox Pascha 2026: April 12, 2026
	easter2026 := CalculateOrthodoxEaster(2026)
	if easter2026.Month() != time.April || easter2026.Day() != 12 {
		t.Errorf("Expected Pascha 2026 on April 12, got %v", easter2026.Format("2006-01-02"))
	}

	// Orthodox Pascha 2025: April 20, 2025
	easter2025 := CalculateOrthodoxEaster(2025)
	if easter2025.Month() != time.April || easter2025.Day() != 20 {
		t.Errorf("Expected Pascha 2025 on April 20, got %v", easter2025.Format("2006-01-02"))
	}
}

func TestMenologionFeastLookup(t *testing.T) {
	// 29 August: St. John the Baptist Beheading
	entry := GetDailySaints(8, 29)
	if len(entry.Saints) == 0 {
		t.Fatalf("Expected saints for August 29, got none")
	}
	if entry.Saints[0].Name != "Ιωάννης ο Πρόδρομος (Αποτομή Κεφαλής)" {
		t.Errorf("Unexpected saint name: %s", entry.Saints[0].Name)
	}
	if entry.Apostolos.Text == "" {
		t.Errorf("Expected Epistle reading for August 29")
	}
}

func TestBuildServiceDynamicInjection(t *testing.T) {
	date := time.Date(2026, 8, 29, 0, 0, 0, 0, time.UTC)
	svc, err := BuildService("morning_prayer", date)
	if err != nil {
		t.Fatalf("BuildService failed: %v", err)
	}

	hasDynamicApolytikion := false
	for _, s := range svc.Sections {
		if s.IsDynamic && s.DynamicType == "apolytikion" {
			hasDynamicApolytikion = true
			if s.Content == "" {
				t.Errorf("Dynamic Apolytikion content was empty")
			}
		}
	}

	if !hasDynamicApolytikion {
		t.Errorf("Expected dynamic Apolytikion section in morning_prayer")
	}
}

func TestFastingRule(t *testing.T) {
	// 29 August: Strict Fast for the Beheading of the Baptist
	date := time.Date(2026, 8, 29, 0, 0, 0, 0, time.UTC)
	rule := CalculateFastingRule(date)
	if rule == "" {
		t.Errorf("Fasting rule returned empty")
	}
}
