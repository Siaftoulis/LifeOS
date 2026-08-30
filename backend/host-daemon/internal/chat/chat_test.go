package chat

import (
	"os"
	"testing"
)

func TestChatDBFlow(t *testing.T) {
	tempDir, err := os.MkdirTemp("", "chat_test_*")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	if err := InitDB(tempDir); err != nil {
		t.Fatalf("InitDB failed: %v", err)
	}

	// 1. Verify default channels exist
	channels, err := GetChannels("")
	if err != nil {
		t.Fatalf("GetChannels failed: %v", err)
	}
	if len(channels) == 0 {
		t.Fatalf("Expected seeded channels, found none")
	}

	familyChannel := channels[0]
	if familyChannel.ID != "chan-family-lounge" {
		t.Errorf("Expected chan-family-lounge, got %s", familyChannel.ID)
	}

	// 2. Create custom direct message channel
	dm, err := CreateChannel("Panos & Alice", true, []string{"panospds", "alice"})
	if err != nil {
		t.Fatalf("CreateChannel failed: %v", err)
	}
	if !dm.IsDirect {
		t.Errorf("Expected IsDirect=true for DM channel")
	}

	// 3. Send message
	msg, err := SaveMessage(dm.ID, "panospds", "Panagiotis", "Hello offline mesh!", "", "")
	if err != nil {
		t.Fatalf("SaveMessage failed: %v", err)
	}
	if msg.Content != "Hello offline mesh!" {
		t.Errorf("Expected content 'Hello offline mesh!', got %s", msg.Content)
	}

	// 4. Query messages
	msgs, err := GetMessages(dm.ID, 50, "")
	if err != nil {
		t.Fatalf("GetMessages failed: %v", err)
	}
	if len(msgs) != 1 {
		t.Fatalf("Expected 1 message, got %d", len(msgs))
	}
	if msgs[0].ID != msg.ID {
		t.Errorf("Message ID mismatch: expected %s, got %s", msg.ID, msgs[0].ID)
	}

	// 5. Search messages by query
	searchRes, err := GetMessages(dm.ID, 50, "mesh")
	if err != nil {
		t.Fatalf("GetMessages with search failed: %v", err)
	}
	if len(searchRes) != 1 {
		t.Errorf("Expected 1 search match, got %d", len(searchRes))
	}
}
