package player

import (
	"math"
)

// CalculateBiologicalCap computes the soft cap BC based on age.
// Formula: BC(Age) = floor(100 / (1 + e^(-0.08 * (Age-15))))
func CalculateBiologicalCap(age float64) int {
	exponent := -0.08 * (age - 15.0)
	bc := 100.0 / (1.0 + math.Exp(exponent))
	return int(math.Floor(bc))
}

// CalculateLifetimeXP calculates total XP required for a target level.
// Formula: LifetimeXP = floor(50 * L^1.8)
func CalculateLifetimeXP(level float64) int {
	xp := 50.0 * math.Pow(level, 1.8)
	return int(math.Floor(xp))
}

// CalculateRawLevel computes the raw level from total XP.
// Formula: L_raw = floor((XP / 50)^0.55)
func CalculateRawLevel(xp int) int {
	lRaw := math.Pow(float64(xp)/50.0, 0.55)
	return int(math.Floor(lRaw))
}

// CalculateEffectiveLevel applies the biological soft cap to the raw level.
// Formula: Level = floor(BC * (1 - e^(-L_raw / BC)))
func CalculateEffectiveLevel(xp int, age float64) int {
	bc := float64(CalculateBiologicalCap(age))
	lRaw := float64(CalculateRawLevel(xp))

	// Prevent division by zero if BC is somehow 0
	if bc == 0 {
		return 0
	}

	level := bc * (1.0 - math.Exp(-lRaw/bc))
	return int(math.Floor(level))
}
