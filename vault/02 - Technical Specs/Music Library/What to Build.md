# What to Build | Music Library

This document specifies the exact SQLite schemas, REST API paths, and Flutter widget components to build for the Music Library personal cloud.

---

## 1. Database Architecture (SQLite / Drift)

Three tables must be defined in the SQLite cache layer to support audio cataloging, playlists, and track mappings.

```sql
-- Schema for Music Tracks Metadata
CREATE TABLE IF NOT EXISTS music_tracks (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    artist TEXT,
    album TEXT,
    track_number INTEGER,
    file_path TEXT NOT NULL,
    lyrics_path TEXT,
    updated_at INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0
);

-- Schema for Music Playlists
CREATE TABLE IF NOT EXISTS playlists (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0
);

-- Schema for Playlist Tracks Reference
CREATE TABLE IF NOT EXISTS playlist_tracks (
    id TEXT PRIMARY KEY,
    playlist_id TEXT NOT NULL,
    track_id TEXT NOT NULL,
    is_dirty INTEGER DEFAULT 0,
    FOREIGN KEY(playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
    FOREIGN KEY(track_id) REFERENCES music_tracks(id) ON DELETE CASCADE
);
```

---

## 2. API Specifications (Go Backend Daemon)

The host daemon manages audio tags scans, serves Subsonic API loops, and retrieves time-synced lyrics.

### REST Endpoints
- **List & Sync Tracks:**
  - `GET /api/v1/music/tracks`
  - Response: `JSON` list of local catalog files, artist names, and ID3 data tags.
- **Audio Streamer Bytes:**
  - `GET /api/v1/music/stream?id={track_id}`
  - Headers: Supports `Range: bytes=X-Y`.
  - Response: Binary audio segment data.
- **Get Sync Lyrics:**
  - `GET /api/v1/music/lyrics?track_id={id}`
  - Response: Synced lyrics JSON arrays.

---

## 3. UI Component Registry (Flutter Client)

All widgets are declared inside `client/lib/presentation/widgets/` or plugins:

- **`MusicDashboardWidget`:** Main interface rendering album grid blocks, playlists items, and queue selections.
- **`MusicPlayerOverlay`:** Bottom sheet player presenting Seek control bars, skip details, and translation hooks.
- **`LyricsSyncViewer`:** Scrolling lyrics view scrolling text inline with active timestamps.
