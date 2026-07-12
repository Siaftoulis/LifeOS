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
	mux.HandleFunc("/api/v1/points/app-costs", handleAppCosts)
	mux.HandleFunc("/api/v1/points/apps/deduct", handleAppDeduct)
}

func handleLeaderboard(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(GetLeaderboard())
}

func handleLedger(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	if r.Method == http.MethodGet {
		json.NewEncoder(w).Encode(GetLedger())
		return
	}

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

	newBalance := AddPointsWithEvent(payload.UserID, payload.Points, payload.Event)

	if newBalance < 0 {
		log.Printf("Appliance Lock Webhooks: Triggering TV Lock Webhook for user %s due to negative balance!", payload.UserID)
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":      "success",
		"new_balance": newBalance,
	})
}

var voucherCosts = map[string]int{
	"v-1": 50,
	"v-2": 100,
	"v-3": 300,
	"v-4": 1000,
}

func handleVoucherRedeem(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var payload struct {
		VoucherID string `json:"voucher_id"`
		UserID    string `json:"user_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		http.Error(w, "Invalid payload", http.StatusBadRequest)
		return
	}

	cost, exists := voucherCosts[payload.VoucherID]
	if !exists {
		cost = 0
	}

	newBalance := AddPointsWithEvent(payload.UserID, -cost, "Redeemed Voucher "+payload.VoucherID)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":         "redeemed",
		"transaction_id": "tx_redeem_" + payload.VoucherID,
		"new_balance":    newBalance,
	})
}

var appCosts = map[string]int{
	"com.instagram.android":      50,
	"com.google.android.youtube": 30,
}

func handleAppCosts(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(appCosts)
	case http.MethodPost:
		var payload struct {
			AppPackage string `json:"app_package"`
			Cost       int    `json:"cost"`
		}
		if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
			http.Error(w, "Invalid payload", http.StatusBadRequest)
			return
		}
		appCosts[payload.AppPackage] = payload.Cost
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]interface{}{"status": "success", "appCosts": appCosts})
	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func handleAppDeduct(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var payload struct {
		UserID     string `json:"user_id"`
		AppPackage string `json:"app_package"`
		Duration   int    `json:"duration"`
	}
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		http.Error(w, "Invalid payload", http.StatusBadRequest)
		return
	}

	costPerLaunch, exists := appCosts[payload.AppPackage]
	if !exists {
		costPerLaunch = 0
	}

	// Deduct points
	newBalance := AddPointsWithEvent(payload.UserID, -costPerLaunch, "Launched "+payload.AppPackage)

	if newBalance < 0 {
		http.Error(w, "Insufficient points", http.StatusPaymentRequired)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":      "success",
		"new_balance": newBalance,
	})
}
