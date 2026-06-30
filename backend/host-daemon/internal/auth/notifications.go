package auth

import (
	"sync"
	"time"
)

type Notification struct {
	ID        string `json:"id"`
	Title     string `json:"title"`
	Message   string `json:"message"`
	Category  string `json:"category"`
	CreatedAt int64  `json:"created_at"`
}

var (
	notifLock     sync.RWMutex
	notifications []Notification
)

func init() {
	// Add an initial startup notification
	AddNotification("sys-start", "LifeOS Online", "Host-daemon connected & monitoring.", "SYSTEM")
}

func AddNotification(id, title, message, category string) {
	notifLock.Lock()
	defer notifLock.Unlock()
	notifications = append(notifications, Notification{
		ID:        id,
		Title:     title,
		Message:   message,
		Category:  category,
		CreatedAt: time.Now().Unix(),
	})

	// Keep only the last 100 notifications to prevent unbounded growth
	if len(notifications) > 100 {
		notifications = notifications[1:]
	}
}

func GetNotifications() []Notification {
	notifLock.RLock()
	defer notifLock.RUnlock()

	// Return a copy to avoid race conditions when marshaling
	cpy := make([]Notification, len(notifications))
	copy(cpy, notifications)
	return cpy
}
