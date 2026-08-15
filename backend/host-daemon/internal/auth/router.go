package auth

import (
	"encoding/json"
	"net"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"lifeos/host-daemon/internal/auth/middleware"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/auth/login", HandleLogin)
	mux.HandleFunc("/api/v1/auth/register", HandleRegister)
	mux.HandleFunc("/api/v1/auth/me", middleware.RequireAuth(HandleMe))
	mux.HandleFunc("/api/v1/auth/lock", HandleLock)
	mux.HandleFunc("/api/v1/auth/users", middleware.RequireAuth(HandleUsers))
	mux.HandleFunc("/api/v1/auth/profile", middleware.RequireAuth(HandleProfile))
	mux.HandleFunc("/api/v1/auth/password", middleware.RequireAuth(HandlePassword))
	mux.HandleFunc("/api/v1/notifications", middleware.RequireAuth(HandleNotifications))
}

type LoginRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

// Simple per-IP login throttle: 5 failures per 5 minutes → blocked.
type ipLimiter struct {
	mu    sync.Mutex
	fails map[string][]time.Time
}

var loginLimiter = &ipLimiter{fails: make(map[string][]time.Time)}

func (l *ipLimiter) blocked(ip string) bool {
	l.mu.Lock()
	defer l.mu.Unlock()
	now := time.Now()
	cutoff := now.Add(-5 * time.Minute)
	fresh := l.fails[ip][:0]
	for _, t := range l.fails[ip] {
		if t.After(cutoff) {
			fresh = append(fresh, t)
		}
	}
	l.fails[ip] = fresh
	return len(fresh) >= 5
}

func (l *ipLimiter) fail(ip string) {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.fails[ip] = append(l.fails[ip], time.Now())
}

func (l *ipLimiter) clear(ip string) {
	l.mu.Lock()
	defer l.mu.Unlock()
	delete(l.fails, ip)
}

func HandleLogin(w http.ResponseWriter, r *http.Request) {
	ip := strings.Split(r.RemoteAddr, ":")[0]
	if loginLimiter.blocked(ip) {
		http.Error(w, "Too many login attempts, try again later", http.StatusTooManyRequests)
		return
	}

	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	user, authenticated := AuthenticateUser(req.Username, req.Password)

	w.Header().Set("Content-Type", "application/json")
	if !authenticated {
		loginLimiter.fail(ip)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"authenticated": false,
		})
		return
	}
	loginLimiter.clear(ip)

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"username": user.Username,
		"role":     user.Role,
		"exp":      time.Now().Add(time.Hour * 24).Unix(),
	})
	tokenString, err := token.SignedString(middleware.JwtSecret)
	if err != nil {
		http.Error(w, "Failed to generate token", http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"authenticated": true,
		"token":         tokenString,
		"role":          user.Role,
		"user":          user,
	})
}

func HandleUsers(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Account creation is an admin-only operation
	role, _ := r.Context().Value(middleware.RoleContextKey).(string)
	if role != "ADMIN" {
		http.Error(w, "Admin privileges required", http.StatusForbidden)
		return
	}

	if r.Method == http.MethodGet {
		users := GetUsers()
		json.NewEncoder(w).Encode(users)
		return
	}

	if r.Method == http.MethodPost {
		var req struct {
			Username string `json:"username"`
			Password string `json:"password"`
			Role     string `json:"role"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		newUser, err := CreateUser(req.Username, req.Password, req.Role)
		if err != nil {
			http.Error(w, err.Error(), http.StatusConflict)
			return
		}
		newUser.PasswordHash = ""
		json.NewEncoder(w).Encode(newUser)
		return
	}

	http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
}

func HandleProfile(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Identity comes from the token, never from the request body
	username, _ := r.Context().Value(middleware.UserContextKey).(string)

	var req struct {
		DisplayName string `json:"display_name"`
		Status      string `json:"status"`
		AvatarAsset string `json:"avatar_asset"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	success := UpdateProfile(username, req.DisplayName, req.Status, req.AvatarAsset)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{"success": success})
}

func HandlePassword(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	username, _ := r.Context().Value(middleware.UserContextKey).(string)

	var req struct {
		OldPassword string `json:"old_password"`
		NewPassword string `json:"new_password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := ChangePassword(username, req.OldPassword, req.NewPassword); err != nil {
		http.Error(w, err.Error(), http.StatusForbidden)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{"success": true})
}

func HandleLock(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"locked": true,
	})
}

func HandleNotifications(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(GetNotifications())
}

func HandleMe(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	username, ok := r.Context().Value(middleware.UserContextKey).(string)
	if !ok || username == "" {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	user, exists := GetUserByUsername(username)
	if !exists {
		http.Error(w, "User not found", http.StatusNotFound)
		return
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"authenticated": true,
		"user":          user,
	})
}

// isTrustedPeer: registration is invite-only. Only loopback, LAN and tailnet
// (CGNAT 100.64.0.0/10) peers may self-register. Requests that arrive through
// the public Cloudflare tunnel carry Cf-Connecting-Ip and are always denied.
func isTrustedPeer(r *http.Request) bool {
	if r.Header.Get("Cf-Connecting-Ip") != "" {
		return false
	}
	ip := net.ParseIP(strings.Split(r.RemoteAddr, ":")[0])
	if ip == nil {
		return false
	}
	return ip.IsLoopback() ||
		ip.IsPrivate() ||
		ip.IsLinkLocalUnicast() ||
		(ip.To4() != nil && ip.To4()[0] == 100 && ip.To4()[1]&0xC0 == 0x40) // 100.64.0.0/10
}

func HandleRegister(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	if !isTrustedPeer(r) {
		http.Error(w, "Registration is invite-only (admin creates accounts)", http.StatusForbidden)
		return
	}

	ip := strings.Split(r.RemoteAddr, ":")[0]
	if loginLimiter.blocked(ip) {
		http.Error(w, "Too many attempts, try again later", http.StatusTooManyRequests)
		return
	}

	var req struct {
		Username string `json:"username"`
		Password string `json:"password"`
		Role     string `json:"role"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Self-registration can never escalate to ADMIN: the role is forced to USER
	// regardless of what the client sends. Admin accounts are created by an
	// existing admin via /api/v1/auth/users.
	newUser, err := CreateUser(req.Username, req.Password, "USER")
	if err != nil {
		loginLimiter.fail(ip)
		http.Error(w, "User already exists or invalid data", http.StatusConflict)
		return
	}

	newUser.PasswordHash = ""
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"user":    newUser,
	})
}
