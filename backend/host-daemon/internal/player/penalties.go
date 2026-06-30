package player

import (
	"math"
)

// CalculateXPDecayRate computes the percentage rate of XP decay.
// Rate = 1% * Base^(d - 1)
// where Base = max(1.0, 2 - WP / 100)
// Returns rate as a decimal (e.g. 0.01 for 1%)
func CalculateXPDecayRate(willpower float64, inactiveDays int) float64 {
	if inactiveDays <= 0 {
		return 0.0
	}

	base := 2.0 - (willpower / 100.0)
	if base < 1.0 {
		base = 1.0
	}

	// Base^(d - 1)
	multiplier := math.Pow(base, float64(inactiveDays-1))

	return 0.01 * multiplier
}

// CalculateAtrophyBuffer computes how many days of inactivity are allowed before stats drop.
// Buffer = 1 + floor(WP / 25)
func CalculateAtrophyBuffer(willpower float64) int {
	buffer := 1.0 + math.Floor(willpower/25.0)
	return int(buffer)
}

// CalculateStatAtrophy computes the points to deduct based on inactive days and buffer.
// Returns -1 points per day beyond the buffer.
func CalculateStatAtrophy(willpower float64, inactiveDays int) int {
	buffer := CalculateAtrophyBuffer(willpower)
	if inactiveDays <= buffer {
		return 0
	}

	daysOver := inactiveDays - buffer
	return daysOver // 1 point per day over buffer
}
