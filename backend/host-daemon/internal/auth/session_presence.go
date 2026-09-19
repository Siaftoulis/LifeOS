package auth

import (
	"net/http"
	"strings"
	"sync"
	"time"
)

type OnlineSession struct {
	Username    string `json:"username"`
	DisplayName string `json:"display_name"`
	Role        string `json:"role"`
	AvatarAsset string `json:"avatar_asset"`
	Frame       string `json:"frame"`
	NameStyle   string `json:"name_style"`
	Status      string `json:"status"`
	Device      string `json:"device"`
	LastActive  int64  `json:"last_active"`
	IsOnline    bool   `json:"is_online"`
}

var (
	presenceMu   sync.RWMutex
	userPresence = make(map[string]*OnlineSession)
)

func parseDevice(r *http.Request) string {
	if r == nil {
		return "Client"
	}
	if dev := r.Header.Get("X-Client-Platform"); dev != "" {
		return dev
	}
	ua := r.UserAgent()
	if strings.Contains(ua, "Android") {
		return "Android Mobile"
	}
	if strings.Contains(ua, "Windows") {
		return "Windows PC"
	}
	if strings.Contains(ua, "iPhone") || strings.Contains(ua, "iPad") {
		return "iOS Device"
	}
	if strings.Contains(ua, "Linux") {
		return "Linux"
	}
	if strings.Contains(ua, "Macintosh") {
		return "macOS"
	}
	return "Web Portal"
}

// RecordUserActivity registers an activity timestamp for a user.
func RecordUserActivity(username string, r *http.Request) {
	if username == "" {
		return
	}
	presenceMu.Lock()
	defer presenceMu.Unlock()

	device := parseDevice(r)

	user, exists := GetUserByUsername(username)
	displayName := username
	role := "USER"
	avatar := ""
	frame := "none"
	nameStyle := "default"
	status := "Online"
	if exists && user != nil {
		if user.DisplayName != "" {
			displayName = user.DisplayName
		}
		role = user.Role
		avatar = user.AvatarAsset
		frame = user.Frame
		nameStyle = user.NameStyle
		if user.Status != "" {
			status = user.Status
		}
	}

	userPresence[username] = &OnlineSession{
		Username:    username,
		DisplayName: displayName,
		Role:        role,
		AvatarAsset: avatar,
		Frame:       frame,
		NameStyle:   nameStyle,
		Status:      status,
		Device:      device,
		LastActive:  time.Now().Unix(),
		IsOnline:    true,
	}
}

// GetOnlineUsers returns all users in the system with their online/offline presence status.
func GetOnlineUsers() []OnlineSession {
	presenceMu.RLock()
	defer presenceMu.RUnlock()

	now := time.Now().Unix()
	const onlineThreshold = 5 * 60 // 5 minutes

	allUsers := GetUsers()
	var result []OnlineSession

	for _, u := range allUsers {
		sess, active := userPresence[u.Username]
		isOnline := false
		lastActive := u.CreatedAt
		device := "Offline"
		if active && sess != nil {
			lastActive = sess.LastActive
			if (now - sess.LastActive) <= onlineThreshold {
				isOnline = true
				device = sess.Device
			}
		}

		result = append(result, OnlineSession{
			Username:    u.Username,
			DisplayName: u.DisplayName,
			Role:        u.Role,
			AvatarAsset: u.AvatarAsset,
			Frame:       u.Frame,
			NameStyle:   u.NameStyle,
			Status:      u.Status,
			Device:      device,
			LastActive:  lastActive,
			IsOnline:    isOnline,
		})
	}

	return result
}
