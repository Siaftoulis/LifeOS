package banking

import (
	"bytes"
	"encoding/json"
	"fmt"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// makeTestPdf assembles a minimal but valid single-page PDF whose text is the
// given string. xref offsets are computed so the parser finds the objects.
func makeTestPdf(text string) []byte {
	var b bytes.Buffer
	b.WriteString("%PDF-1.4\n")
	objects := []string{
		"1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n",
		"2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n",
		"3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\nendobj\n",
		"",
		"5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n",
	}
	stream := fmt.Sprintf("BT /F1 12 Tf 72 720 Td (%s) Tj ET", text)
	objects[3] = fmt.Sprintf("4 0 obj\n<< /Length %d >>\nstream\n%s\nendstream\nendobj\n", len(stream), stream)

	offsets := make([]int, len(objects))
	for i, o := range objects {
		offsets[i] = b.Len()
		b.WriteString(o)
	}
	xrefPos := b.Len()
	b.WriteString("xref\n0 6\n0000000000 65535 f \n")
	for _, off := range offsets {
		fmt.Fprintf(&b, "%010d 00000 n \n", off)
	}
	fmt.Fprintf(&b, "trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF\n", xrefPos)
	return b.Bytes()
}

func TestParsePdfHandler(t *testing.T) {
	mux := http.NewServeMux()
	RegisterRoutes(mux)

	body := &bytes.Buffer{}
	w := multipart.NewWriter(body)
	fw, err := w.CreateFormFile("file", "apotheksh-receipt.pdf")
	if err != nil {
		t.Fatal(err)
	}
	fw.Write(makeTestPdf("ΠΟΣΟ ΠΛΗΡΩΜΗΣ: 45,00 €  Ημερομηνία: 12/08/2026"))
	w.Close()

	req := httptest.NewRequest(http.MethodPost, "/api/v1/banking/parse-pdf", body)
	req.Header.Set("Content-Type", w.FormDataContentType())
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", rec.Code, rec.Body.String())
	}
	var resp struct {
		Amount      float64 `json:"amount"`
		AmountCents int64   `json:"amount_cents"`
		Title       string  `json:"title"`
		Date        string  `json:"date"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatal(err)
	}
	if resp.AmountCents != 4500 || resp.Amount != 45.00 {
		t.Errorf("amount = %d cents / %.2f, want 4500 / 45.00", resp.AmountCents, resp.Amount)
	}
	if resp.Title != "apotheksh-receipt" {
		t.Errorf("title = %q, want %q", resp.Title, "apotheksh-receipt")
	}
	if resp.Date != "12/08/2026" {
		t.Errorf("date = %q, want 12/08/2026", resp.Date)
	}

	// Garbage input must fail loudly, never silently return a stub amount.
	req2 := httptest.NewRequest(http.MethodPost, "/api/v1/banking/parse-pdf", strings.NewReader("not a pdf"))
	req2.Header.Set("Content-Type", "application/octet-stream")
	rec2 := httptest.NewRecorder()
	mux.ServeHTTP(rec2, req2)
	if rec2.Code != http.StatusBadRequest {
		t.Errorf("garbage input status = %d, want 400", rec2.Code)
	}
}