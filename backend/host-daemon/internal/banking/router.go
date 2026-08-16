package banking

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"
)

type Transaction struct {
	ID       string  `json:"id"`
	Title    string  `json:"title"`
	Amount   float64 `json:"amount"`
	Category string  `json:"category"`
	Date     string  `json:"date"`
	Type     string  `json:"type"`
}

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/banking/parse-pdf", handleParsePdf)

	mux.HandleFunc("/api/v1/banking/status", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		
		var balance float64
		err := DB.QueryRow("SELECT balance FROM accounts WHERE id = 'acc-1'").Scan(&balance)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		response := map[string]interface{}{
			"balance": balance,
			"monthly_income_cents": 420000,
			"total_bills_cents": 18640,
		}
		json.NewEncoder(w).Encode(response)
	})

	mux.HandleFunc("/api/v1/banking/transactions", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		rows, err := DB.Query("SELECT id, title, amount, category, date, type FROM transactions ORDER BY rowid DESC")
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		defer rows.Close()

		var txs []Transaction
		for rows.Next() {
			var t Transaction
			if err := rows.Scan(&t.ID, &t.Title, &t.Amount, &t.Category, &t.Date, &t.Type); err == nil {
				txs = append(txs, t)
			}
		}
		
		if txs == nil {
			txs = []Transaction{}
		}

		json.NewEncoder(w).Encode(txs)
	})
}

// handleParsePdf accepts a multipart PDF upload, extracts the amount (and
// invoice date) and archives the receipt. The client confirms before saving
// the transaction.
func handleParsePdf(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	r.Body = http.MaxBytesReader(w, r.Body, 20<<20)
	f, h, err := r.FormFile("file")
	if err != nil {
		http.Error(w, "missing file field", http.StatusBadRequest)
		return
	}
	defer f.Close()
	if !strings.HasSuffix(strings.ToLower(h.Filename), ".pdf") {
		http.Error(w, "only PDF files are accepted", http.StatusBadRequest)
		return
	}

	tmp, err := os.CreateTemp("", "receipt-*.pdf")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer os.Remove(tmp.Name())
	if _, err := io.Copy(tmp, f); err != nil {
		tmp.Close()
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	tmp.Close()

	amountCents, err := ExtractBillAmount(tmp.Name())
	if err != nil {
		http.Error(w, err.Error(), http.StatusUnprocessableEntity)
		return
	}

	os.MkdirAll("./data/receipts", 0755)
	archivePath := filepath.Join("./data/receipts", fmt.Sprintf("%s-%s", time.Now().Format("20060102-150405"), h.Filename))
	archived, err := os.Open(tmp.Name())
	if err == nil {
		defer archived.Close()
		dest, derr := os.Create(archivePath)
		if derr == nil {
			io.Copy(dest, archived)
			dest.Close()
		}
	}

	title := strings.TrimSuffix(h.Filename, filepath.Ext(h.Filename))
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"amount":       float64(amountCents) / 100.0,
		"amount_cents": amountCents,
		"title":        title,
		"date":         ExtractBillDate(tmp.Name()),
		"archived_at":  archivePath,
	})
}
