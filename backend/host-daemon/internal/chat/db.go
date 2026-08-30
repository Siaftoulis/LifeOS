package chat

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"path/filepath"
	"time"

	"github.com/google/uuid"
	_ "modernc.org/sqlite"
)

var DB *sql.DB

func InitDB(dataDir string) error {
	dbPath := filepath.Join(dataDir, "chat.db")
	log.Printf("Initializing chat database at %s", dbPath)

	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return fmt.Errorf("failed to open chat db: %v", err)
	}

	DB = db
	return createTables()
}

func createTables() error {
	query := `
	CREATE TABLE IF NOT EXISTS chat_channels (
		id TEXT PRIMARY KEY,
		name TEXT NOT NULL,
		is_direct INTEGER NOT NULL DEFAULT 0,
		members_json TEXT NOT NULL DEFAULT '[]',
		created_at INTEGER NOT NULL,
		last_message_at INTEGER NOT NULL
	);

	CREATE TABLE IF NOT EXISTS chat_messages (
		id TEXT PRIMARY KEY,
		channel_id TEXT NOT NULL,
		sender_id TEXT NOT NULL,
		sender_name TEXT NOT NULL,
		content TEXT NOT NULL,
		attachment_url TEXT,
		attachment_type TEXT,
		created_at INTEGER NOT NULL,
		status TEXT NOT NULL DEFAULT 'sent',
		FOREIGN KEY (channel_id) REFERENCES chat_channels(id) ON DELETE CASCADE
	);

	CREATE INDEX IF NOT EXISTS idx_chat_messages_channel ON chat_messages(channel_id, created_at);
	`

	_, err := DB.Exec(query)
	if err != nil {
		return fmt.Errorf("failed to create chat tables: %v", err)
	}

	// Seed default general channel if empty
	var count int
	err = DB.QueryRow("SELECT COUNT(*) FROM chat_channels").Scan(&count)
	if err == nil && count == 0 {
		seedDefaultChannels()
	}

	return nil
}

func seedDefaultChannels() {
	now := time.Now().Unix()
	generalID := "chan-family-lounge"
	membersJSON, _ := json.Marshal([]string{"panospds", "all"})

	_, err := DB.Exec(`
		INSERT INTO chat_channels (id, name, is_direct, members_json, created_at, last_message_at)
		VALUES (?, ?, ?, ?, ?, ?)
	`, generalID, "Family Lounge", 0, string(membersJSON), now, now)

	if err != nil {
		log.Printf("Failed to seed chat channels: %v", err)
		return
	}

	welcomeMsgID := uuid.New().String()
	_, _ = DB.Exec(`
		INSERT INTO chat_messages (id, channel_id, sender_id, sender_name, content, created_at, status)
		VALUES (?, ?, ?, ?, ?, ?, ?)
	`, welcomeMsgID, generalID, "system", "LifeOS Core", "Welcome to LifeOS Mesh Messenger! Messages sync seamlessly across devices and work peer-to-peer even offline.", now, "delivered")
}

func GetChannels(query string) ([]Channel, error) {
	if DB == nil {
		return nil, fmt.Errorf("chat DB not initialized")
	}

	sqlQuery := "SELECT id, name, is_direct, members_json, created_at, last_message_at FROM chat_channels"
	var args []interface{}

	if query != "" {
		sqlQuery += " WHERE name LIKE ?"
		args = append(args, "%"+query+"%")
	}

	sqlQuery += " ORDER BY last_message_at DESC"

	rows, err := DB.Query(sqlQuery, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	channels := make([]Channel, 0)
	for rows.Next() {
		var c Channel
		var isDirect int
		var membersRaw string

		if err := rows.Scan(&c.ID, &c.Name, &isDirect, &membersRaw, &c.CreatedAt, &c.LastMessageAt); err != nil {
			continue
		}
		c.IsDirect = isDirect == 1
		_ = json.Unmarshal([]byte(membersRaw), &c.Members)

		// Fetch last message for preview
		var lastMsg Message
		err := DB.QueryRow(`
			SELECT id, channel_id, sender_id, sender_name, content, COALESCE(attachment_url, ''), COALESCE(attachment_type, ''), created_at, status
			FROM chat_messages WHERE channel_id = ? ORDER BY created_at DESC LIMIT 1
		`, c.ID).Scan(&lastMsg.ID, &lastMsg.ChannelID, &lastMsg.SenderID, &lastMsg.SenderName, &lastMsg.Content, &lastMsg.AttachmentURL, &lastMsg.AttachmentType, &lastMsg.CreatedAt, &lastMsg.Status)

		if err == nil {
			c.LastMessage = &lastMsg
		}

		channels = append(channels, c)
	}

	return channels, nil
}

func CreateChannel(name string, isDirect bool, members []string) (*Channel, error) {
	if DB == nil {
		return nil, fmt.Errorf("chat DB not initialized")
	}

	id := "chan-" + uuid.New().String()[:8]
	if isDirect {
		id = "dm-" + uuid.New().String()[:8]
	}

	now := time.Now().Unix()
	isDirectInt := 0
	if isDirect {
		isDirectInt = 1
	}

	membersJSON, _ := json.Marshal(members)

	_, err := DB.Exec(`
		INSERT INTO chat_channels (id, name, is_direct, members_json, created_at, last_message_at)
		VALUES (?, ?, ?, ?, ?, ?)
	`, id, name, isDirectInt, string(membersJSON), now, now)

	if err != nil {
		return nil, err
	}

	return &Channel{
		ID:            id,
		Name:          name,
		IsDirect:      isDirect,
		Members:       members,
		CreatedAt:     now,
		LastMessageAt: now,
	}, nil
}

func GetMessages(channelID string, limit int, query string) ([]Message, error) {
	if DB == nil {
		return nil, fmt.Errorf("chat DB not initialized")
	}

	if limit <= 0 || limit > 200 {
		limit = 50
	}

	sqlQuery := `
		SELECT id, channel_id, sender_id, sender_name, content, COALESCE(attachment_url, ''), COALESCE(attachment_type, ''), created_at, status
		FROM chat_messages WHERE channel_id = ?
	`
	args := []interface{}{channelID}

	if query != "" {
		sqlQuery += " AND content LIKE ?"
		args = append(args, "%"+query+"%")
	}

	sqlQuery += " ORDER BY created_at ASC LIMIT ?"
	args = append(args, limit)

	rows, err := DB.Query(sqlQuery, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	messages := make([]Message, 0)
	for rows.Next() {
		var m Message
		if err := rows.Scan(&m.ID, &m.ChannelID, &m.SenderID, &m.SenderName, &m.Content, &m.AttachmentURL, &m.AttachmentType, &m.CreatedAt, &m.Status); err != nil {
			continue
		}
		messages = append(messages, m)
	}

	return messages, nil
}

func SaveMessage(channelID, senderID, senderName, content, attachmentURL, attachmentType string) (*Message, error) {
	if DB == nil {
		return nil, fmt.Errorf("chat DB not initialized")
	}

	msgID := "msg-" + uuid.New().String()
	now := time.Now().Unix()

	_, err := DB.Exec(`
		INSERT INTO chat_messages (id, channel_id, sender_id, sender_name, content, attachment_url, attachment_type, created_at, status)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
	`, msgID, channelID, senderID, senderName, content, attachmentURL, attachmentType, now, "delivered")

	if err != nil {
		return nil, err
	}

	// Update channel's last_message_at timestamp
	_, _ = DB.Exec("UPDATE chat_channels SET last_message_at = ? WHERE id = ?", now, channelID)

	return &Message{
		ID:             msgID,
		ChannelID:      channelID,
		SenderID:       senderID,
		SenderName:     senderName,
		Content:        content,
		AttachmentURL:  attachmentURL,
		AttachmentType: attachmentType,
		CreatedAt:      now,
		Status:         "delivered",
	}, nil
}
