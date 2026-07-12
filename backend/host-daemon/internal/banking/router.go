package banking

import (
	"encoding/json"
	"net/http"
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
	mux.HandleFunc("/api/v1/banking/parse-pdf", func(w http.ResponseWriter, r *http.Request) {
		// keeping old stub
		response := map[string]interface{}{"provider": "DEI"}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)
	})

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
