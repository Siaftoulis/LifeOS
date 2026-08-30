package chat

type Channel struct {
	ID            string   `json:"id"`
	Name          string   `json:"name"`
	IsDirect      bool     `json:"is_direct"`
	Members       []string `json:"members"`
	CreatedAt     int64    `json:"created_at"`
	LastMessageAt int64    `json:"last_message_at"`
	LastMessage   *Message `json:"last_message,omitempty"`
	UnreadCount   int      `json:"unread_count"`
}

type Message struct {
	ID             string `json:"id"`
	ChannelID      string `json:"channel_id"`
	SenderID       string `json:"sender_id"`
	SenderName     string `json:"sender_name"`
	Content        string `json:"content"`
	AttachmentURL  string `json:"attachment_url,omitempty"`
	AttachmentType string `json:"attachment_type,omitempty"` // image, file, audio
	CreatedAt      int64  `json:"created_at"`
	Status         string `json:"status"` // sent, delivered, read
}

type SendMessageRequest struct {
	ChannelID      string `json:"channel_id"`
	Content        string `json:"content"`
	AttachmentURL  string `json:"attachment_url,omitempty"`
	AttachmentType string `json:"attachment_type,omitempty"`
}

type CreateChannelRequest struct {
	Name     string   `json:"name"`
	IsDirect bool     `json:"is_direct"`
	Members  []string `json:"members"`
}

type MarkReadRequest struct {
	ChannelID string `json:"channel_id"`
	MessageID string `json:"message_id,omitempty"`
}
