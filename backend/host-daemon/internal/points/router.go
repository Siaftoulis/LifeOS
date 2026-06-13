package points

import (
	"encoding/json"
	"log"
	"net/http"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/points/leaderboard", handleLeaderboard)
	mux.HandleFunc("/api/v1/points/ledger", handleLedger)
	mux.HandleFunc("/api/v1/points/vouchers/redeem", handleVoucherRedeem)
}

func handleLeaderboard(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode([]map[string]interface{}{
		{"username": "Alice (Admin)", "points": 1540, "rank": 1},
		{"username": "Bob", "points": 820, "rank": 2},
		{"username": "Charlie", "points": 310, "rank": 3},
	})
}

func handleLedger(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	// Parse payload
	var payload struct {
		UserID string `json:"user_id"`
		Event  string `json:"event"`
		Points int    `json:"points"`
	}
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		http.Error(w, "Invalid payload", http.StatusBadRequest)
		return
	}

	// Stub processing delta and checking lockouts
	currentBalance := 100 // Stub
	newBalance := currentBalance + payload.Points

	if newBalance < 0 {
		log.Printf("Appliance Lock Webhooks: Triggering TV Lock Webhook for user %s due to negative balance!", payload.UserID)
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "success",
		"new_balance": newBalance,
	})
}

func handleVoucherRedeem(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "redeemed",
		"transaction_id": "tx_abc123",
	})
}
