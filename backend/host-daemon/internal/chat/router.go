package chat

import (
	"encoding/json"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"lifeos/host-daemon/internal/auth/middleware"
	"lifeos/host-daemon/internal/bus"
)

func RegisterRoutes(mux *http.ServeMux) {
	// Channels list / search & creation
	mux.HandleFunc("/api/v1/chat/channels", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		if r.Method == http.MethodGet {
			query := r.URL.Query().Get("q")
			channels, err := GetChannels(query)
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			json.NewEncoder(w).Encode(map[string]interface{}{
				"channels": channels,
			})
			return
		}

		if r.Method == http.MethodPost {
			var req CreateChannelRequest
			if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
				http.Error(w, "Bad Request", http.StatusBadRequest)
				return
			}

			if req.Name == "" {
				http.Error(w, "Channel name cannot be empty", http.StatusBadRequest)
				return
			}

			ch, err := CreateChannel(req.Name, req.IsDirect, req.Members)
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}

			senderID, _ := r.Context().Value(middleware.UserContextKey).(string)
			bus.Publish(bus.Event{
				Topic:   "chat:channel_created",
				UserID:  senderID,
				At:      time.Now(),
				Payload: ch,
			})

			json.NewEncoder(w).Encode(ch)
			return
		}

		http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
	})

	// Messages query & send
	mux.HandleFunc("/api/v1/chat/messages", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		if r.Method == http.MethodGet {
			channelID := r.URL.Query().Get("channel_id")
			if channelID == "" {
				http.Error(w, "Missing channel_id", http.StatusBadRequest)
				return
			}

			limitStr := r.URL.Query().Get("limit")
			limit := 50
			if l, err := strconv.Atoi(limitStr); err == nil && l > 0 {
				limit = l
			}

			query := r.URL.Query().Get("q")
			messages, err := GetMessages(channelID, limit, query)
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}

			json.NewEncoder(w).Encode(map[string]interface{}{
				"messages": messages,
			})
			return
		}

		if r.Method == http.MethodPost {
			var req SendMessageRequest
			if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
				http.Error(w, "Bad Request", http.StatusBadRequest)
				return
			}

			if req.ChannelID == "" || (req.Content == "" && req.AttachmentURL == "") {
				http.Error(w, "channel_id and content/attachment are required", http.StatusBadRequest)
				return
			}

			senderID, _ := r.Context().Value(middleware.UserContextKey).(string)
			if senderID == "" {
				senderID = "panospds"
			}
			senderName := senderID

			msg, err := SaveMessage(req.ChannelID, senderID, senderName, req.Content, req.AttachmentURL, req.AttachmentType)
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}

			// Broadcast live event across bus and to all WebSocket clients
			bus.Publish(bus.Event{
				Topic:   "chat:message",
				UserID:  senderID,
				At:      time.Now(),
				Payload: msg,
			})

			json.NewEncoder(w).Encode(msg)
			return
		}

		http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
	})

	// Attachment / Voice message binary upload
	mux.HandleFunc("/api/v1/chat/upload", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
			return
		}

		// Maximum 25MB attachment
		if err := r.ParseMultipartForm(25 << 20); err != nil {
			http.Error(w, "File too large or invalid multipart form", http.StatusBadRequest)
			return
		}

		file, header, err := r.FormFile("file")
		if err != nil {
			http.Error(w, "Missing file in upload", http.StatusBadRequest)
			return
		}
		defer file.Close()

		ext := filepath.Ext(header.Filename)
		if ext == "" {
			ext = ".bin"
		}

		attType := r.FormValue("type")
		if attType == "" {
			attType = "file"
		}

		attachDir := filepath.Join(".", "data", "chat_attachments")
		os.MkdirAll(attachDir, 0755)

		fileID := uuid.New().String() + ext
		destPath := filepath.Join(attachDir, fileID)

		dst, err := os.Create(destPath)
		if err != nil {
			http.Error(w, "Failed to store attachment", http.StatusInternalServerError)
			return
		}
		defer dst.Close()

		if _, err := io.Copy(dst, file); err != nil {
			http.Error(w, "Failed to write attachment data", http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{
			"file_id": fileID,
			"url":     "/api/v1/chat/attachment?id=" + fileID,
			"type":    attType,
		})
	})

	// Attachment / Voice message binary serve
	mux.HandleFunc("/api/v1/chat/attachment", func(w http.ResponseWriter, r *http.Request) {
		id := r.URL.Query().Get("id")
		if id == "" || strings.Contains(id, "..") || strings.Contains(id, "/") || strings.Contains(id, "\\") {
			http.Error(w, "Invalid file ID", http.StatusBadRequest)
			return
		}

		attachDir := filepath.Join(".", "data", "chat_attachments")
		filePath := filepath.Join(attachDir, id)

		if _, err := os.Stat(filePath); os.IsNotExist(err) {
			http.Error(w, "Attachment not found", http.StatusNotFound)
			return
		}

		http.ServeFile(w, r, filePath)
	})
}
