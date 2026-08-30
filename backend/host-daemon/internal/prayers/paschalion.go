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

	julianEaster := time.Date(year, time.Month(month), day, 0, 0, 0, 0, time.UTC)
	gregorianEaster := julianEaster.AddDate(0, 0, 13)
	return gregorianEaster
}

// MovableDates holds all dynamic feast dates for a liturgical year
type MovableDates struct {
	Year               int
	PublicanAndPharisee time.Time
	MeatfareSunday     time.Time
	CheesefareSunday   time.Time
	CleanMonday        time.Time
	PalmSunday         time.Time
	HolyThursday       time.Time
	HolyFriday         time.Time
	HolySaturday       time.Time
	Pascha             time.Time
	BrightMonday       time.Time
	ThomasSunday       time.Time
	Ascension          time.Time
	Pentecost          time.Time
	AllSaints          time.Time
	ApostlesStart      time.Time // Monday after All Saints (start of Apostles' Fast)
	ApostlesEnd        time.Time // 28 June (fixed end of Apostles' Fast)
}

// GetMovableDates returns the full movable cycle for a given year
func GetMovableDates(year int) MovableDates {
	pascha := CalculateOrthodoxEaster(year)
	allSaints := pascha.AddDate(0, 0, 56)

	// Apostles' Fast: Monday after All Saints to 28 June
	// Find the Monday after All Saints
	apostlesStart := allSaints
	for apostlesStart.Weekday() != time.Monday {
		apostlesStart = apostlesStart.AddDate(0, 0, 1)
	}

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
		AllSaints:          allSaints,
		ApostlesStart:      apostlesStart,
		ApostlesEnd:        time.Date(year, time.June, 28, 0, 0, 0, 0, time.UTC),
	}
}

// GetOctoechosTone calculates the Ήχος (Tone) of the week for any date.
func GetOctoechosTone(date time.Time) string {
	pascha := CalculateOrthodoxEaster(date.Year())
	thomasSunday := pascha.AddDate(0, 0, 7)

	// Bright Week (Pascha to Thomas Sunday): Tone 1 Διακαινήσιμος
	if (date.After(pascha) || date.Equal(pascha)) && date.Before(thomasSunday) {
		return "Ήχος Α' (Διακαινήσιμος)"
	}

	// After Thomas Sunday: compute from this year's Thomas Sunday
	if !date.Before(thomasSunday) {
		diffDays := int(date.Sub(thomasSunday).Hours() / 24)
		weeks := diffDays / 7
		toneIdx := (weeks % 8) + 1
		return toneFromIndex(toneIdx)
	}

	// Before Pascha: use previous year's Octoechos cycle
	// Find previous year's Thomas Sunday
	paschaPrev := CalculateOrthodoxEaster(date.Year() - 1)
	thomasPrev := paschaPrev.AddDate(0, 0, 7)

	// If we're after previous year's Thomas Sunday, compute from there
	if !date.Before(thomasPrev) {
		diffDays := int(date.Sub(thomasPrev).Hours() / 24)
		weeks := diffDays / 7
		toneIdx := (weeks % 8) + 1
		return toneFromIndex(toneIdx)
	}

	// Before previous Thomas Sunday (very rare — Sept-Oct of year before Pascha)
	// Use Tone 8 as fallback (previous cycle would have ended)
	return "Ήχος Πλ. Δ'"
}

// GetOctoechosToneIndex returns 1-8 tone number for a given date
func GetOctoechosToneIndex(date time.Time) int {
	pascha := CalculateOrthodoxEaster(date.Year())
	thomasSunday := pascha.AddDate(0, 0, 7)

	if (date.After(pascha) || date.Equal(pascha)) && date.Before(thomasSunday) {
		return 1
	}

	if !date.Before(thomasSunday) {
		diffDays := int(date.Sub(thomasSunday).Hours() / 24)
		weeks := diffDays / 7
		return (weeks % 8) + 1
	}

	paschaPrev := CalculateOrthodoxEaster(date.Year() - 1)
	thomasPrev := paschaPrev.AddDate(0, 0, 7)

	if !date.Before(thomasPrev) {
		diffDays := int(date.Sub(thomasPrev).Hours() / 24)
		weeks := diffDays / 7
		return (weeks % 8) + 1
	}

	return 8
}

func toneFromIndex(idx int) string {
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
	if idx >= 1 && idx <= 8 {
		return tones[idx-1]
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
	apostlesStart := time.Date(movable.ApostlesStart.Year(), movable.ApostlesStart.Month(), movable.ApostlesStart.Day(), 0, 0, 0, 0, time.UTC)
	apostlesEnd := time.Date(movable.ApostlesEnd.Year(), movable.ApostlesEnd.Month(), movable.ApostlesEnd.Day(), 0, 0, 0, 0, time.UTC)

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

	// Apostles' Fast (Monday after All Saints to 28 June)
	if (d.After(apostlesStart) || d.Equal(apostlesStart)) && (d.Before(apostlesEnd) || d.Equal(apostlesEnd)) {
		return "Απόστολική Νηστεία", "Νηστεία Αγίων Αποστόλων"
	}

	// Standard Octoechos / Menologion period (after Apostles' Fast end to before Triodion)
	// Week counter capped at 19 (Matthean cycle) then restarts for Lukan
	diffFromAllSaints := int(d.Sub(allSaints).Hours() / 24)
	if diffFromAllSaints > 0 {
		weekNum := (diffFromAllSaints / 7) + 1
		if weekNum > 34 {
			weekNum = 34 // Cap at reasonable max
		}
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
	cheesefareSunday := time.Date(movable.CheesefareSunday.Year(), movable.CheesefareSunday.Month(), movable.CheesefareSunday.Day(), 0, 0, 0, 0, time.UTC)
	meafareSunday := time.Date(movable.MeatfareSunday.Year(), movable.MeatfareSunday.Month(), movable.MeatfareSunday.Day(), 0, 0, 0, 0, time.UTC)
	apostlesStart := time.Date(movable.ApostlesStart.Year(), movable.ApostlesStart.Month(), movable.ApostlesStart.Day(), 0, 0, 0, 0, time.UTC)
	apostlesEnd := time.Date(movable.ApostlesEnd.Year(), movable.ApostlesEnd.Month(), movable.ApostlesEnd.Day(), 0, 0, 0, 0, time.UTC)

	// Bright Week: Fast-free completely
	if (d.After(pascha) || d.Equal(pascha)) && d.Before(brightWeekEnd) {
		return FastNone
	}

	// Cheesefare Week (Meatfare Sunday to Clean Monday): Dairy/eggs allowed, no meat
	if (d.After(meafareSunday) || d.Equal(meafareSunday)) && d.Before(cleanMonday) {
		if d.Equal(cheesefareSunday) {
			return FastDairy // Cheesefare Sunday itself
		}
		// Weekdays in Cheesefare Week: dairy allowed
		return FastDairy
	}

	// Great Lent (Clean Monday to Pascha)
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

	// Apostles' Fast (Monday after All Saints to 28 June)
	if (d.After(apostlesStart) || d.Equal(apostlesStart)) && (d.Before(apostlesEnd) || d.Equal(apostlesEnd)) {
		// Fish allowed on weekends and feast days
		if weekday == time.Saturday || weekday == time.Sunday {
			return FastFish
		}
		return FastWineOil
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

	// Eve of Theophany (5 January): Strict fast
	if date.Month() == 1 && date.Day() == 5 {
		return FastStrict
	}

	// Exaltation of the Cross (14 September): Strict fast
	if date.Month() == 9 && date.Day() == 14 {
		return FastStrict
	}

	// Standard Wednesday & Friday fasts
	if weekday == time.Wednesday || weekday == time.Friday {
		return FastWineOil
	}

	return FastNone
}
