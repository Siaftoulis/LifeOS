package engine

import (
	"time"
)

type EntityType string

const (
	TypeEvent           EntityType = "event"
	TypeTask            EntityType = "task"
	TypeHabit           EntityType = "habit"
	TypeMetric          EntityType = "metric"
	TypeZenLog          EntityType = "zen_log"
	TypeBankAccount     EntityType = "bank_account"
	TypeBankTransaction EntityType = "bank_transaction"
	TypeAccountingCred  EntityType = "accounting_cred"
	TypeAccountingDoc   EntityType = "accounting_doc"
	TypeFlashcardDeck   EntityType = "flashcard_deck"
	TypeFlashcard       EntityType = "flashcard"
	TypeFlashcardReview EntityType = "flashcard_review"
	TypeKnowledgeTopic  EntityType = "knowledge_topic"
	TypeMediaMovie      EntityType = "media_movie"
	TypeMediaTrack      EntityType = "media_track"
	TypeMediaPlaylist   EntityType = "media_playlist"
	TypeYoutubeVideo    EntityType = "youtube_video"
	TypeSmartDevice     EntityType = "smart_device"
	TypeDeviceSchedule  EntityType = "device_schedule"
	TypeGeofence        EntityType = "geofence"
	TypeLocationLog     EntityType = "location_log"
	TypeCloudBackup     EntityType = "cloud_backup"
	TypeTorrentItem     EntityType = "torrent_item"
	TypeSharedFile      EntityType = "shared_file"
	TypeNotification    EntityType = "notification"
)

// Entity represents the core atomic unit of data in LifeOS General Engine
type Entity struct {
	ID         string                 `json:"id"`
	Type       EntityType             `json:"type"`
	CreatorID  string                 `json:"creator_id"`
	Payload    map[string]interface{} `json:"payload"`
	SharedWith []string               `json:"shared_with"`
	AssignedTo string                 `json:"assigned_to,omitempty"`
	CreatedAt  time.Time              `json:"created_at"`
	UpdatedAt  time.Time              `json:"updated_at"`
}
