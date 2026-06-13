package banking

import (
	"os"
)

// ExtractBillAmount is a stub implementation for Phase 1.
// In Phase 2, this will parse the actual PDF using a library like github.com/ledongthuc/pdfreader.
func ExtractBillAmount(pdfPath string) (int64, error) {
	// Stub: Return a mock value of €186.40 (18640 cents)
	if _, err := os.Stat(pdfPath); os.IsNotExist(err) {
		return 0, err
	}
	return 18640, nil
}
