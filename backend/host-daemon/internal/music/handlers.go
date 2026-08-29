package music

// Music HTTP handlers have been decomposed into dedicated domain files:
// - handlers_liked.go      (Favorite / liked track endpoints)
// - handlers_playlist.go   (Playlist CRUD & track ordering endpoints)
// - handlers_downloads.go  (Download queue management endpoints)
// - handlers_history.go    (Listening history & stats endpoints)
// - handlers_smart.go      (Smart playlists & recommendation endpoints)
// - models.go              (Music domain structs)