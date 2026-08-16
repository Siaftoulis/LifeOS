package points

import (
	"regexp"
	"testing"
)

func TestVoucherCodeFormat(t *testing.T) {
	codeRe := regexp.MustCompile(`^LF-[A-Z2-9]{4}-[A-Z2-9]{4}-[A-Z2-9]{4}$`)
	for i := 0; i < 1000; i++ {
		code := newVoucherCode()
		if !codeRe.MatchString(code) {
			t.Fatalf("bad code format: %q", code)
		}
	}
}

func TestStarsFor(t *testing.T) {
	if starsFor(0) != 0 || starsFor(99) != 0 || starsFor(100) != 1 || starsFor(1540) != 15 {
		t.Fatalf("starsFor conversion wrong")
	}
}

func TestCatalogCostsMatchStarPrices(t *testing.T) {
	for _, item := range storeCatalog {
		if item.CostStars <= 0 {
			t.Fatalf("item %s must cost stars", item.ID)
		}
	}
}