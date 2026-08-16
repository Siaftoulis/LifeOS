package banking

import (
	"fmt"
	"os"
	"regexp"
	"strconv"
	"strings"

	"github.com/ledongthuc/pdf"
)

var (
	amountRe = regexp.MustCompile(`(?:€|\$)?\s*([0-9]{1,3}(?:[.,][0-9]{3})*[.,][0-9]{2})`)
	// year-first (2026-08-12) before dd/mm/yyyy before dd/mm/yy
	dateRe = regexp.MustCompile(`\d{4}[/.-]\d{1,2}[/.-]\d{1,2}|\d{1,2}[/.-]\d{1,2}[/.-]\d{4}|\d{1,2}[/.-]\d{1,2}[/.-]\d{2}`)
)

// normalizeAmount turns both "1,234.56" and "1.234,56" into "1234.56":
// the last separator is the decimal one.
func normalizeAmount(s string) string {
	lastSep := strings.LastIndexAny(s, ",.")
	var b strings.Builder
	for i, c := range s {
		if c == ',' || c == '.' {
			if i == lastSep {
				b.WriteByte('.')
			}
			continue
		}
		b.WriteRune(c)
	}
	return b.String()
}

// extractAmountFromText returns the first euro-style amount found in the text,
// in cents. Empty string → error (no amount found).
func extractAmountFromText(content string) (int64, error) {
	matches := amountRe.FindStringSubmatch(content)
	if len(matches) < 2 {
		return 0, fmt.Errorf("no amount found in PDF")
	}
	amtStr := normalizeAmount(matches[1])
	parts := strings.Split(amtStr, ".")
	if len(parts) != 2 {
		return 0, fmt.Errorf("no amount found in PDF")
	}
	dollars, err := strconv.ParseInt(parts[0], 10, 64)
	if err != nil {
		return 0, fmt.Errorf("no amount found in PDF")
	}
	cents, err := strconv.ParseInt(parts[1], 10, 64)
	if err != nil {
		return 0, fmt.Errorf("no amount found in PDF")
	}
	return dollars*100 + cents, nil
}

// extractDateFromText returns the first date-looking string (dd/mm/yyyy etc.).
func extractDateFromText(content string) string {
	return dateRe.FindString(content)
}

func readPdfText(pdfPath string) (string, error) {
	if _, err := os.Stat(pdfPath); os.IsNotExist(err) {
		return "", err
	}

	f, r, err := pdf.Open(pdfPath)
	if err != nil {
		return "", err
	}
	defer f.Close()

	var contentBuilder strings.Builder
	for pageIndex := 1; pageIndex <= r.NumPage(); pageIndex++ {
		p := r.Page(pageIndex)
		if p.V.IsNull() {
			continue
		}
		text, err := p.GetPlainText(nil)
		if err == nil {
			contentBuilder.WriteString(text)
		}
	}
	return contentBuilder.String(), nil
}

// ExtractBillAmount parses the actual PDF and extracts an amount in cents.
func ExtractBillAmount(pdfPath string) (int64, error) {
	content, err := readPdfText(pdfPath)
	if err != nil {
		return 0, err
	}
	return extractAmountFromText(content)
}

// ExtractBillDate returns the invoice date found in the PDF, if any.
func ExtractBillDate(pdfPath string) string {
	content, err := readPdfText(pdfPath)
	if err != nil {
		return ""
	}
	return extractDateFromText(content)
}