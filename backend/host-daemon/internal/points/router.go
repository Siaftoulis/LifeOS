package points

import (
	"crypto/rand"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"time"

	"lifeos/host-daemon/internal/auth/middleware"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/points/leaderboard", handleLeaderboard)
	mux.HandleFunc("/api/v1/points/ledger", handleLedger)
	mux.HandleFunc("/api/v1/points/balance", handleBalance)
	mux.HandleFunc("/api/v1/points/store", handleStore)
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
	// ponytail: GET only. The raw-POST award path is gone — points come from
	// telemetry rules, quests and app deductions, never from a client number.
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	json.NewEncoder(w).Encode(GetLedger())
}

// Stars are the family-facing currency: 100 points = 1 star. Derived, not a
// separate ledger — one source of truth (the points balance).
func starsFor(points int) int { return points / 100 }

func handleBalance(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	username, _ := r.Context().Value(middleware.UserContextKey).(string)
	if username == "" {
		username = "panospds"
	}
	balance := GetBalance(username)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"user_id": username,
		"points":  balance,
		"stars":   starsFor(balance),
	})
}

type storeItem struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	CostStars int   `json:"cost_stars"`
}

// store catalog: the rewards shop. Everything priced in stars; the server
// converts to points at redemption.
var storeCatalog = []storeItem{
	{ID: "v-1", Name: "Cinema Night Voucher", CostStars: 1},
	{ID: "v-2", Name: "Game Time Voucher", CostStars: 2},
	{ID: "v-3", Name: "Weekend Trip Voucher", CostStars: 5},
	{ID: "v-4", Name: "Dream Day Voucher", CostStars: 10},
}

func handleStore(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	username, _ := r.Context().Value(middleware.UserContextKey).(string)
	if username == "" {
		username = "panospds"
	}
	balance := GetBalance(username)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"items":  storeCatalog,
		"points": balance,
		"stars":  starsFor(balance),
	})
}


func handleVoucherRedeem(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var payload struct {
		VoucherID string `json:"voucher_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		http.Error(w, "Invalid payload", http.StatusBadRequest)
		return
	}

	// Server decides the user from the authenticated session — the client's
	// local DB id (u-admin-1) is not the daemon's user.
	username, _ := r.Context().Value(middleware.UserContextKey).(string)
	if username == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	var item *storeItem
	for i := range storeCatalog {
		if storeCatalog[i].ID == payload.VoucherID {
			item = &storeCatalog[i]
			break
		}
	}
	if item == nil {
		http.Error(w, "Unknown voucher", http.StatusNotFound)
		return
	}

	costPoints := item.CostStars * 100
	newBalance := AddPointsWithEvent(username, -costPoints, "Redeemed Voucher: "+item.Name)

	code := newVoucherCode()
	appendIssuedVoucher(username, item, code)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":         "redeemed",
		"voucher":        item.Name,
		"code":           code,
		"transaction_id": "tx_redeem_" + payload.VoucherID + "_" + time.Now().Format("20060102150405"),
		"new_balance":    newBalance,
		"stars":          starsFor(newBalance),
	})
}

// newVoucherCode mints LF-XXXX-XXXX-XXXX codes from crypto/rand.
func newVoucherCode() string {
	const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // no 0/O/1/I
	parts := make([]string, 3)
	for p := 0; p < 3; p++ {
		buf := make([]byte, 4)
		if _, err := rand.Read(buf); err != nil {
			return fmt.Sprintf("LF-%d", time.Now().UnixNano())
		}
		part := make([]byte, 4)
		for i := 0; i < 4; i++ {
			part[i] = chars[int(buf[i])%len(chars)]
		}
		parts[p] = string(part)
	}
	return "LF-" + parts[0] + "-" + parts[1] + "-" + parts[2]
}

// Issued vouchers persist so a code survives daemon restarts.
type issuedVoucher struct {
	Code      string `json:"code"`
	UserID    string `json:"user_id"`
	VoucherID string `json:"voucher_id"`
	IssuedAt  string `json:"issued_at"`
}

func appendIssuedVoucher(userID string, item *storeItem, code string) {
	var issued []issuedVoucher
	if data, err := os.ReadFile("./data/vouchers_issued.json"); err == nil {
		json.Unmarshal(data, &issued)
	}
	issued = append(issued, issuedVoucher{
		Code:      code,
		UserID:    userID,
		VoucherID: item.ID,
		IssuedAt:  time.Now().Format(time.RFC3339),
	})
	if data, err := json.MarshalIndent(issued, "", "  "); err == nil {
		os.MkdirAll("./data", 0755)
		os.WriteFile("./data/vouchers_issued.json", data, 0644)
	}
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
