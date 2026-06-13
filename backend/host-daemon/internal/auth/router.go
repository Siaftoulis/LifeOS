package auth

import (
	"encoding/json"
	"net/http"
	"golang.org/x/crypto/bcrypt"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/auth/unlock", HandleUnlock)
	mux.HandleFunc("/api/v1/auth/lock", HandleLock)
	mux.HandleFunc("/api/v1/notifications", HandleNotifications)
}

type UnlockRequest struct {
	PINHash string `json:"pin_hash"`
}

func HandleUnlock(w http.ResponseWriter, r *http.Request) {
	var req UnlockRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Stubbed master PIN hash for "1234"
	masterHash, _ := bcrypt.GenerateFromPassword([]byte("1234"), bcrypt.DefaultCost)

	err := bcrypt.CompareHashAndPassword(masterHash, []byte(req.PINHash))
	authenticated := err == nil

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"authenticated": authenticated,
		"token":         "mock_jwt_token",
		"role":          "ADMIN",
	})
}

func HandleLock(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"locked": true,
	})
}

func HandleNotifications(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode([]map[string]interface{}{
		{"title": "System Update", "message": "LifeOS v2.4 downloaded."},
		{"title": "Security", "message": "Failed login attempt."},
	})
}
