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
	mux.HandleFunc("/api/v1/auth/profiles", HandlePublicProfiles)
	mux.HandleFunc("/api/v1/auth/me", middleware.RequireAuth(HandleMe))
	mux.HandleFunc("/api/v1/auth/lock", HandleLock)
	mux.HandleFunc("/api/v1/auth/users", middleware.RequireAuth(HandleUsers))
	mux.HandleFunc("/api/v1/auth/profile", middleware.RequireAuth(HandleProfile))
	mux.HandleFunc("/api/v1/auth/password", middleware.RequireAuth(HandlePassword))
	mux.HandleFunc("/api/v1/auth/online", middleware.RequireAuth(HandleOnlineUsers))
	mux.HandleFunc("/api/v1/auth/heartbeat", middleware.RequireAuth(HandleHeartbeat))
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
		"exp":      time.Now().Add(time.Hour * 24 * 30).Unix(),
	})
	tokenString, err := token.SignedString(middleware.JwtSecret)
	if err != nil {
		http.Error(w, "Failed to generate token", http.StatusInternalServerError)
		return
	}

	RecordUserActivity(user.Username, r)

	json.NewEncoder(w).Encode(map[string]interface{}{
		"authenticated": true,
		"token":         tokenString,
		"role":          user.Role,
		"user":          user,
	})
}

// HandlePublicProfiles returns list of profiles for the lockscreen/login switcher.
// Passwords and hashes are completely omitted.
func HandlePublicProfiles(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	users := GetUsers()
	type PublicProfile struct {
		ID          string `json:"id"`
		Username    string `json:"username"`
		Email       string `json:"email"`
		Role        string `json:"role"`
		AvatarAsset string `json:"avatar_asset"`
		DisplayName string `json:"display_name"`
		Status      string `json:"status"`
	}

	var profiles []PublicProfile
	for _, u := range users {
		profiles = append(profiles, PublicProfile{
			ID:          u.ID,
			Username:    u.Username,
			Email:       u.Email,
			Role:        u.Role,
			AvatarAsset: u.AvatarAsset,
			DisplayName: u.DisplayName,
			Status:      u.Status,
		})
	}
	if profiles == nil {
		profiles = []PublicProfile{}
	}

	json.NewEncoder(w).Encode(profiles)
}

func HandleUsers(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	// Account management is an admin-only operation
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
			Username    string `json:"username"`
			Password    string `json:"password"`
			Role        string `json:"role"`
			Email       string `json:"email"`
			DisplayName string `json:"display_name"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		if req.Role == "" {
			req.Role = "USER"
		}

		newUser, err := CreateUser(req.Username, req.Password, req.Role)
		if err != nil {
			http.Error(w, err.Error(), http.StatusConflict)
			return
		}
		if req.Email != "" || req.DisplayName != "" {
			_, _ = UpdateUser(req.Username, req.Role, req.DisplayName, req.Email, "Active")
			newUser.Email = req.Email
			if req.DisplayName != "" {
				newUser.DisplayName = req.DisplayName
			}
		}
		newUser.PasswordHash = ""
		json.NewEncoder(w).Encode(newUser)
		return
	}

	if r.Method == http.MethodDelete {
		username := r.URL.Query().Get("username")
		if username == "" {
			var req struct {
				Username string `json:"username"`
			}
			_ = json.NewDecoder(r.Body).Decode(&req)
			username = req.Username
		}
		if username == "" {
			http.Error(w, "Missing username parameter", http.StatusBadRequest)
			return
		}
		if username == "panospds" {
			http.Error(w, "Cannot delete root administrator", http.StatusBadRequest)
			return
		}

		currentAdmin, _ := r.Context().Value(middleware.UserContextKey).(string)
		if username == currentAdmin {
			http.Error(w, "Cannot delete yourself while logged in", http.StatusBadRequest)
			return
		}

		err := DeleteUser(username)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		json.NewEncoder(w).Encode(map[string]any{"success": true, "deleted": username})
		return
	}

	if r.Method == http.MethodPatch || r.Method == http.MethodPut {
		var req struct {
			Username    string `json:"username"`
			Role        string `json:"role"`
			DisplayName string `json:"display_name"`
			Email       string `json:"email"`
			Status      string `json:"status"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Username == "" {
			http.Error(w, "Invalid request", http.StatusBadRequest)
			return
		}

		updatedUser, err := UpdateUser(req.Username, req.Role, req.DisplayName, req.Email, req.Status)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		json.NewEncoder(w).Encode(updatedUser)
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
		NewUsername string `json:"new_username"`
		DisplayName string `json:"display_name"`
		Status      string `json:"status"`
		AvatarAsset string `json:"avatar_asset"`
		Frame       string `json:"frame"`
		NameStyle   string `json:"name_style"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	updatedUser, err := UpdateProfile(username, req.NewUsername, req.DisplayName, req.Status, req.AvatarAsset, req.Frame, req.NameStyle)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	RecordUserActivity(updatedUser.Username, r)

	var newToken string
	if updatedUser.Username != username {
		token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
			"username": updatedUser.Username,
			"role":     updatedUser.Role,
			"exp":      time.Now().Add(time.Hour * 24 * 30).Unix(),
		})
		newToken, _ = token.SignedString(middleware.JwtSecret)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"user":    updatedUser,
		"token":   newToken,
	})
}

func HandleOnlineUsers(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(GetOnlineUsers())
}

func HandleHeartbeat(w http.ResponseWriter, r *http.Request) {
	username, _ := r.Context().Value(middleware.UserContextKey).(string)
	if username != "" {
		RecordUserActivity(username, r)
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{"status": "ok"})
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

	RecordUserActivity(username, r)

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
