package banking

import (
	"encoding/json"
	"net/http"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/banking/parse-pdf", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		// Stub implementation returning mock JSON
		response := map[string]interface{}{
			"provider":                "DEI",
			"amount_cents":            18640,
			"due_date":                1781222400000,
			"rounded_target_cents":    20000,
			"rollover_deducted_cents": 1360,
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)
	})

	mux.HandleFunc("/api/v1/banking/status", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		// Stub implementation returning aggregated statistics
		response := map[string]interface{}{
			"monthly_income_cents":        100000,
			"total_bills_cents":           18640,
			"rounded_bill_transfer_cents": 20000,
			"rollover_surplus_cents":      1360,
			"allocations": map[string]int64{
				"essentials_cents":                 500000,
				"savings_cents":                    200000,
				"personal_allowance_user_cents":    178000,
				"personal_allowance_partner_cents": 122000,
			},
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)
	})
}
