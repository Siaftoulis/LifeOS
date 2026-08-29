package music

type Playlist struct {
	ID            string `json:"id"`
	Name          string `json:"name"`
	Description   string `json:"description"`
	CoverArtURL   string `json:"cover_art_url"`
	IsSmart       bool   `json:"is_smart"`
	SmartType     string `json:"smart_type"`
	SmartConfig   string `json:"smart_config"`
	TrackCount    int    `json:"track_count"`
	TotalDuration int64  `json:"total_duration"`
	CreatedAt     int64  `json:"created_at"`
	UpdatedAt     int64  `json:"updated_at"`
}

type PlaylistTrack struct {
	Track    Track `json:"track"`
	Position int   `json:"position"`
}

type DownloadQueueItem struct {
	ID              string `json:"id"`
	TrackID         string `json:"track_id"`
	URL             string `json:"url"`
	DestinationPath string `json:"destination_path"`
	Status          string `json:"status"`
	Priority        int    `json:"priority"`
	RetryCount      int    `json:"retry_count"`
	TotalBytes      int64  `json:"total_bytes"`
	DownloadedBytes int64  `json:"downloaded_bytes"`
	ErrorMessage    string `json:"error_message"`
	WiFiOnly        bool   `json:"wifi_only"`
	ChargingOnly    bool   `json:"charging_only"`
	CreatedAt       int64  `json:"created_at"`
	StartedAt       int64  `json:"started_at"`
	CompletedAt     int64  `json:"completed_at"`
}

type HistoryItem struct {
	ID             string  `json:"id"`
	TrackID        string  `json:"track_id"`
	PlayedAt       int64   `json:"played_at"`
	PositionMs     int64   `json:"position_ms"`
	DurationMs     int64   `json:"duration_ms"`
	CompletionRate float64 `json:"completion_rate"`
	Skipped        bool    `json:"skipped"`
	Source         string  `json:"source"`
	Title          string  `json:"title"`
	Artist         string  `json:"artist"`
	Album          string  `json:"album"`
	ThumbnailURL   string  `json:"thumbnail_url"`
}

type Stats struct {
	TotalPlays    int64    `json:"total_plays"`
	UniqueTracks  int64    `json:"unique_tracks"`
	UniqueArtists int64    `json:"unique_artists"`
	TotalMs       int64    `json:"total_ms"`
	TopArtists    []string `json:"top_artists"`
	TopGenres     []string `json:"top_genres"`
}
