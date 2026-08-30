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

func TestBuildDivineLiturgyChrysostom(t *testing.T) {
	date := time.Date(2026, 8, 30, 0, 0, 0, 0, time.UTC) // Sunday
	svc, err := BuildService("divine_liturgy_chrysostom", date)
	if err != nil {
		t.Fatalf("Failed to build Divine Liturgy Chrysostom: %v", err)
	}

	if len(svc.Sections) < 10 {
		t.Errorf("Expected at least 10 sections in Divine Liturgy, got %d", len(svc.Sections))
	}

	dynamicTypes := make(map[string]bool)
	for _, sec := range svc.Sections {
		if sec.IsDynamic {
			dynamicTypes[sec.DynamicType] = true
		}
	}

	expectedTypes := []string{"antiphon", "eisodikon", "apolytikion", "kontakion", "trisagion", "epistle", "gospel", "megalynarion", "koinonikon", "apolysis"}
	for _, et := range expectedTypes {
		if !dynamicTypes[et] {
			t.Errorf("Expected dynamic section of type '%s' in Divine Liturgy", et)
		}
	}
}

func TestBuildDivineLiturgyBasil(t *testing.T) {
	date := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC) // St Basil feast
	svc, err := BuildService("divine_liturgy_basil", date)
	if err != nil {
		t.Fatalf("Failed to build Divine Liturgy Basil: %v", err)
	}

	hasEpiSoiChairei := false
	for _, sec := range svc.Sections {
		if sec.DynamicType == "megalynarion" && (sec.Header == "Εξαιρέτως της Παναγίας (Επί σοί χαίρει)") {
			hasEpiSoiChairei = true
		}
	}
	if !hasEpiSoiChairei {
		t.Errorf("Expected 'Επί σοί χαίρει' megalynarion in St Basil Liturgy")
	}
}

func TestKatavasiesResolution(t *testing.T) {
	// Christmas Eve / Dec 25
	dec25 := time.Date(2026, 12, 25, 0, 0, 0, 0, time.UTC)
	katNativity := GetSeasonalKatavasies(dec25)
	if katNativity.ID != "nativity" {
		t.Errorf("Expected nativity Katavasies for Dec 25, got %s", katNativity.ID)
	}

	// August 30 (Holy Cross season)
	aug30 := time.Date(2026, 8, 30, 0, 0, 0, 0, time.UTC)
	katCross := GetSeasonalKatavasies(aug30)
	if katCross.ID != "holy_cross" {
		t.Errorf("Expected holy_cross Katavasies for Aug 30, got %s", katCross.ID)
	}
}

func TestParakleseisAndArtoklasia(t *testing.T) {
	date := time.Date(2026, 8, 30, 0, 0, 0, 0, time.UTC)

	// Test St Nektarios Paraklesis
	nek, err := BuildService("paraklesis_st_nektarios", date)
	if err != nil || len(nek.Sections) == 0 {
		t.Fatalf("Failed to build St. Nektarios Paraklesis")
	}

	// Test St Paisios Paraklesis
	pai, err := BuildService("paraklesis_st_paisios", date)
	if err != nil || len(pai.Sections) == 0 {
		t.Fatalf("Failed to build St. Paisios Paraklesis")
	}

	// Test Artoklasia
	arto, err := BuildService("service_artoklasia_litany", date)
	if err != nil || len(arto.Sections) == 0 {
		t.Fatalf("Failed to build Artoklasia service")
	}

	// Test Generic Saint Paraklesis
	gen, err := BuildService("paraklesis_generic", date)
	if err != nil || len(gen.Sections) == 0 {
		t.Fatalf("Failed to build Generic Saint Paraklesis")
	}
}


