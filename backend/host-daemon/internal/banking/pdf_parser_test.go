package banking

import "testing"

func TestExtractAmountFromText(t *testing.T) {
	cases := []struct {
		text string
		want int64
		err  bool
	}{
		{"Total: 186.40 EUR", 18640, false},
		{"ΠΟΣΟ ΠΛΗΡΩΜΗΣ: 45,00 €", 4500, false},
		{"Amount due €1,234.56", 123456, false},
		{"ΠΟΣΟ ΠΛΗΡΩΜΗΣ: 1.234,56 €", 123456, false},
		{"No numbers here", 0, true},
		{"Date: 12/08/2026, nothing else", 0, true},
	}
	for _, c := range cases {
		got, err := extractAmountFromText(c.text)
		if c.err != (err != nil) {
			t.Errorf("extractAmountFromText(%q) err=%v, want err=%v", c.text, err, c.err)
		}
		if !c.err && got != c.want {
			t.Errorf("extractAmountFromText(%q) = %d, want %d", c.text, got, c.want)
		}
	}
}

func TestExtractDateFromText(t *testing.T) {
	cases := []struct {
		text string
		want string
	}{
		{"Invoice date 12/08/2026, amount 45.00", "12/08/2026"},
		{"Εκδόθηκε στις 2026-08-12", "2026-08-12"},
		{"Nothing here", ""},
	}
	for _, c := range cases {
		if got := extractDateFromText(c.text); got != c.want {
			t.Errorf("extractDateFromText(%q) = %q, want %q", c.text, got, c.want)
		}
	}
}