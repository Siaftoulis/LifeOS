package banking

import "math"

// CalculateTransferTarget determines the rounded target amount and the new rollover surplus.
func CalculateTransferTarget(rawBillCents int64, lastMonthSurplus int64) (int64, int64) {
	// Subtract surplus from target
	adjustedTarget := rawBillCents - lastMonthSurplus
	if adjustedTarget < 0 {
		adjustedTarget = 0
	}

	// Round up to nearest €10 increment
	roundedEuro := math.Ceil(float64(adjustedTarget)/1000.0) * 10.0
	roundedTargetCents := int64(roundedEuro * 100.0)

	// New rollover surplus to save for next month
	newSurplus := roundedTargetCents - adjustedTarget

	return roundedTargetCents, newSurplus
}
