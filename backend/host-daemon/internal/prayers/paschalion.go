package prayers

import (
	"fmt"
	"time"
)

// CalculateOrthodoxEaster computes the Gregorian date of Orthodox Pascha for any given year
// Uses Meeus's Julian Easter algorithm with the 13-day Gregorian offset for 1900–2099.
func CalculateOrthodoxEaster(year int) time.Time {
	a := year % 4
	b := year % 7
	c := year % 19
	d := (19*c + 15) % 30
	e := (2*a + 4*b - d + 34) % 7
	month := (d + e + 114) / 31
	day := ((d + e + 114) % 31) + 1

	// Julian Easter date
	julianEaster := time.Date(year, time.Month(month), day, 0, 0, 0, 0, time.UTC)

	// Gregorian offset is +13 days for 1900–2099
	gregorianEaster := julianEaster.AddDate(0, 0, 13)
	return gregorianEaster
}

// MovableDates holds all dynamic feast dates for a liturgical year
type MovableDates struct {
	Year               int
	PublicanAndPharisee time.Time // Κυριακή Τελώνου και Φαρισαίου (-70 days)
	MeatfareSunday     time.Time // Κυριακή Απόκρεω (-56 days)
	CheesefareSunday   time.Time // Κυριακή Τυρινής (-49 days)
	CleanMonday        time.Time // Καθαρά Δευτέρα (-48 days)
	PalmSunday         time.Time // Κυριακή των Βαΐων (-7 days)
	HolyThursday       time.Time // Μεγάλη Πέμπτη (-3 days)
	HolyFriday         time.Time // Μεγάλη Παρασκευή (-2 days)
	HolySaturday       time.Time // Μέγα Σάββατον (-1 day)
	Pascha             time.Time // Άγιον Πάσχα (0 days)
	BrightMonday       time.Time // Δευτέρα της Διακαινησίμου (+1 day)
	ThomasSunday       time.Time // Κυριακή του Θωμά (+7 days)
	Ascension          time.Time // Η Ανάληψις του Κυρίου (+39 days)
	Pentecost          time.Time // Αγία Πεντηκοστή (+49 days)
	AllSaints          time.Time // Κυριακή των Αγίων Πάντων (+56 days)
}

// GetMovableDates returns the full movable cycle for a given year
func GetMovableDates(year int) MovableDates {
	pascha := CalculateOrthodoxEaster(year)
	return MovableDates{
		Year:               year,
		PublicanAndPharisee: pascha.AddDate(0, 0, -70),
		MeatfareSunday:     pascha.AddDate(0, 0, -56),
		CheesefareSunday:   pascha.AddDate(0, 0, -49),
		CleanMonday:        pascha.AddDate(0, 0, -48),
		PalmSunday:         pascha.AddDate(0, 0, -7),
		HolyThursday:       pascha.AddDate(0, 0, -3),
		HolyFriday:         pascha.AddDate(0, 0, -2),
		HolySaturday:       pascha.AddDate(0, 0, -1),
		Pascha:             pascha,
		BrightMonday:       pascha.AddDate(0, 0, 1),
		ThomasSunday:       pascha.AddDate(0, 0, 7),
		Ascension:          pascha.AddDate(0, 0, 39),
		Pentecost:          pascha.AddDate(0, 0, 49),
		AllSaints:          pascha.AddDate(0, 0, 56),
	}
}

// GetOctoechosTone calculates the Ήχος (Tone) of the week for any date.
// The Octoechos cycle restarts on Thomas Sunday as Tone 1 (Ήχος Α').
func GetOctoechosTone(date time.Time) string {
	pascha := CalculateOrthodoxEaster(date.Year())
	thomasSunday := pascha.AddDate(0, 0, 7)

	// If date is before Thomas Sunday of current year, use previous year's cycle if before Pascha
	if date.Before(pascha) {
		// During Great Lent and Holy Week, services use special Triodion tones
		return "Ήχος Τριωδίου"
	}
	if date.Equal(pascha) || (date.After(pascha) && date.Before(thomasSunday)) {
		return "Ήχος Α' (Διακαινήσιμος)"
	}

	// Calculate weeks elapsed since Thomas Sunday
	diffDays := int(date.Sub(thomasSunday).Hours() / 24)
	weeks := diffDays / 7
	toneIdx := (weeks % 8) + 1

	tones := []string{
		"Ήχος Α'",
		"Ήχος Β'",
		"Ήχος Γ'",
		"Ήχος Δ'",
		"Ήχος Πλ. Α'",
		"Ήχος Πλ. Β'",
		"Ήχος Βαρύς",
		"Ήχος Πλ. Δ'",
	}
	if toneIdx >= 1 && toneIdx <= 8 {
		return tones[toneIdx-1]
	}
	return "Ήχος Α'"
}

// GetLiturgicalPeriod determines which liturgical book and period governs the day
func GetLiturgicalPeriod(date time.Time) (period string, movableName string) {
	movable := GetMovableDates(date.Year())

	d := time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, time.UTC)
	cleanMonday := time.Date(movable.CleanMonday.Year(), movable.CleanMonday.Month(), movable.CleanMonday.Day(), 0, 0, 0, 0, time.UTC)
	palmSunday := time.Date(movable.PalmSunday.Year(), movable.PalmSunday.Month(), movable.PalmSunday.Day(), 0, 0, 0, 0, time.UTC)
	pascha := time.Date(movable.Pascha.Year(), movable.Pascha.Month(), movable.Pascha.Day(), 0, 0, 0, 0, time.UTC)
	pentecost := time.Date(movable.Pentecost.Year(), movable.Pentecost.Month(), movable.Pentecost.Day(), 0, 0, 0, 0, time.UTC)
	allSaints := time.Date(movable.AllSaints.Year(), movable.AllSaints.Month(), movable.AllSaints.Day(), 0, 0, 0, 0, time.UTC)

	if d.Equal(pascha) {
		return "Πεντηκοστάριον", "Η ΑΓΙΑ ΚΑΙ ΜΕΓΑΛΗ ΚΥΡΙΑΚΗ ΤΟΥ ΠΑΣΧΑ"
	}
	if (d.After(cleanMonday) || d.Equal(cleanMonday)) && d.Before(palmSunday) {
		return "Τριώδιον (Αγία Τεσσαρακοστή)", "Περίοδος Μεγάλης Τεσσαρακοστής"
	}
	if (d.After(palmSunday) || d.Equal(palmSunday)) && d.Before(pascha) {
		return "Τριώδιον (Αγία & Μεγάλη Εβδομάς)", "Αγία και Μεγάλη Εβδομάς των Παθών"
	}
	if d.After(pascha) && (d.Before(pentecost) || d.Equal(pentecost)) {
		return "Πεντηκοστάριον", "Πασχάλιος Περίοδος Πεντηκοσταρίου"
	}
	if d.After(pentecost) && (d.Before(allSaints) || d.Equal(allSaints)) {
		return "Πεντηκοστάριον", "Εβδομάς του Αγίου Πνεύματος"
	}

	// Standard Octoechos / Menologion period
	diffFromAllSaints := int(d.Sub(allSaints).Hours() / 24)
	if diffFromAllSaints > 0 {
		weekNum := (diffFromAllSaints / 7) + 1
		return "Οκτώηχος & Μηναίον", fmt.Sprintf("%dη Εβδομάδα Ματθαίου/Λουκά", weekNum)
	}

	return "Οκτώηχος & Μηναίον", "Τακτική Περίοδος"
}

// CalculateFastingRule calculates the fasting rule based on liturgical calendar & day of week
func CalculateFastingRule(date time.Time) FastingType {
	movable := GetMovableDates(date.Year())
	weekday := date.Weekday()

	d := time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, time.UTC)
	pascha := time.Date(movable.Pascha.Year(), movable.Pascha.Month(), movable.Pascha.Day(), 0, 0, 0, 0, time.UTC)
	brightWeekEnd := pascha.AddDate(0, 0, 7)
	cleanMonday := time.Date(movable.CleanMonday.Year(), movable.CleanMonday.Month(), movable.CleanMonday.Day(), 0, 0, 0, 0, time.UTC)

	// Bright Week (Διακαινήσιμος): Fast-free completely
	if (d.After(pascha) || d.Equal(pascha)) && d.Before(brightWeekEnd) {
		return FastNone
	}

	// Great Lent (Μεγάλη Τεσσαρακοστή)
	if (d.After(cleanMonday) || d.Equal(cleanMonday)) && d.Before(pascha) {
		// Annunciation (25 March) and Palm Sunday allow Fish
		if (date.Month() == 3 && date.Day() == 25) || d.Equal(time.Date(movable.PalmSunday.Year(), movable.PalmSunday.Month(), movable.PalmSunday.Day(), 0, 0, 0, 0, time.UTC)) {
			return FastFish
		}
		// Saturdays & Sundays allow Wine & Oil
		if weekday == time.Saturday || weekday == time.Sunday {
			return FastWineOil
		}
		return FastStrict
	}

	// Dormition Fast (1 - 14 August)
	if date.Month() == 8 && date.Day() >= 1 && date.Day() <= 14 {
		// Transfiguration of the Lord (6 August): Fish allowed
		if date.Day() == 6 {
			return FastFish
		}
		if weekday == time.Saturday || weekday == time.Sunday {
			return FastWineOil
		}
		return FastStrict
	}

	// Nativity Fast (15 November - 24 December)
	if (date.Month() == 11 && date.Day() >= 15) || (date.Month() == 12 && date.Day() <= 24) {
		if date.Month() == 12 && date.Day() > 17 {
			// Strict week before Christmas
			if weekday == time.Saturday || weekday == time.Sunday {
				return FastWineOil
			}
			return FastStrict
		}
		// Fish allowed on weekends and non-Wednesday/Friday feast days
		if weekday == time.Saturday || weekday == time.Sunday || (weekday != time.Wednesday && weekday != time.Friday) {
			return FastFish
		}
		return FastWineOil
	}

	// After Nativity to Theophany Eve (25 Dec - 4 Jan): Fast-free
	if (date.Month() == 12 && date.Day() >= 25) || (date.Month() == 1 && date.Day() <= 4) {
		return FastNone
	}

	// Standard Wednesday & Friday fasts
	if weekday == time.Wednesday || weekday == time.Friday {
		return FastWineOil
	}

	return FastNone
}
