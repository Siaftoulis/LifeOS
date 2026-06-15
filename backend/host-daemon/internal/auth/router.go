package auth

import (
	"encoding/json"
	"net/http"
	"time"
)

func RegisterRoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/v1/auth/login", HandleLogin)
	mux.HandleFunc("/api/v1/auth/lock", HandleLock)
	mux.HandleFunc("/api/v1/auth/users", HandleUsers)
	mux.HandleFunc("/api/v1/auth/profile", HandleProfile)
	mux.HandleFunc("/api/v1/notifications", HandleNotifications)
}

type LoginRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

func HandleLogin(w http.ResponseWriter, r *http.Request) {
	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	user, authenticated := AuthenticateUser(req.Username, req.Password)

	w.Header().Set("Content-Type", "application/json")
	if !authenticated {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"authenticated": false,
		})
		return
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"authenticated": true,
		"token":         "mock_jwt_token_" + user.Username,
		"role":          user.Role,
		"user":          user,
	})
}

func HandleUsers(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method == http.MethodGet {
		users := GetUsers()
		// Clear passwords
		for i := range users {
			users[i].PasswordHash = ""
		}
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

	var req struct {
		Username    string `json:"username"`
		DisplayName string `json:"display_name"`
		Status      string `json:"status"`
		AvatarAsset string `json:"avatar_asset"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	success := UpdateProfile(req.Username, req.DisplayName, req.Status, req.AvatarAsset)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{"success": success})
}

func HandleLock(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"locked": true,
	})
}

var startTime = time.Now()

func HandleNotifications(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	
	elapsed := time.Since(startTime)
	
	templates := []map[string]interface{}{
		{"id": "mock-sys-1", "title": "System Update", "message": "LifeOS v2.4 downloaded successfully.", "category": "SYSTEM"},
		{"id": "mock-habit-1", "title": "Habit Reminder", "message": "Drink water reminder (3/8 cups).", "category": "HABIT"},
		{"id": "mock-sec-1", "title": "Security Log", "message": "Failed login attempt from ip 192.168.1.50.", "category": "SECURITY"},
		{"id": "mock-fin-1", "title": "Financial Alert", "message": "Eurobank balance carrying over surplus: 124.50€.", "category": "FINANCIAL"},
		{"id": "mock-vm-1", "title": "VM Manager", "message": "Hyper-V Dev-Node changed state to RUNNING.", "category": "SYSTEM"},
		{"id": "mock-yt-1", "title": "YouTube Client", "message": "Finished download of 'Drift Tutorial'.", "category": "SYSTEM"},
		{"id": "mock-map-1", "title": "Geofence Alert", "message": "Device exited 'Home Zone'.", "category": "SECURITY"},
	}
	
	var activeNotifications []map[string]interface{}
	count := int(elapsed.Seconds() / 15)
	if count > len(templates) {
		count = len(templates)
	}
	
	for i := 0; i < count; i++ {
		createdTime := startTime.Add(time.Duration(i*15) * time.Second).Unix()
		note := map[string]interface{}{
			"id":         templates[i]["id"],
			"title":      templates[i]["title"],
			"message":    templates[i]["message"],
			"category":   templates[i]["category"],
			"created_at": createdTime,
		}
		activeNotifications = append(activeNotifications, note)
	}
	
	if len(activeNotifications) == 0 {
		activeNotifications = append(activeNotifications, map[string]interface{}{
			"id":         "mock-start",
			"title":      "LifeOS Online",
			"message":    "Host-daemon connected & monitoring.",
			"category":   "SYSTEM",
			"created_at": startTime.Unix(),
		})
	}
	
	json.NewEncoder(w).Encode(activeNotifications)
}
