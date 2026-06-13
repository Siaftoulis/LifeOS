# What to Build | YouTube Client

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/YouTube Client|YouTube Client]]



This document specifies the exact SQLite schemas, REST API paths, and Flutter widget components to build for the YouTube Client gated platform.

---

## 1. Database Architecture (SQLite / Drift)

Two tables must be defined in the SQLite cache layer to support screen time tracking, active usage sessions, and downloaded media indexes.

```sql
-- Schema for Screen Time Sessions Logs
CREATE TABLE IF NOT EXISTS youtube_sessions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    start_time INTEGER NOT NULL, -- Unix timestamp
    duration_seconds INTEGER DEFAULT 0,
    cost_points INTEGER DEFAULT 0,
    is_dirty INTEGER DEFAULT 0
);

-- Schema for Downloaded Offline Videos
CREATE TABLE IF NOT EXISTS youtube_downloads (
    id TEXT PRIMARY KEY,
    video_id TEXT NOT NULL UNIQUE,
    title TEXT NOT NULL,
    file_path TEXT NOT NULL,
    size_bytes INTEGER NOT NULL,
    created_at INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0
);
```

---

## 2. API Specifications (Go Backend Daemon)

The host daemon wraps the yt-dlp downloading agent, operates active screen gates timers, and syncs watchlist rules.

### REST Endpoints
- **List Downloaded Media:**
  - `GET /api/v1/youtube/videos`
  - Response: `JSON` list of local cached files, video sizes, and titles.
- **Trigger yt-dlp Video Download:**
  - `POST /api/v1/youtube/download`
  - Payload: `{"video_url": "https://www.youtube.com/watch?v=..."}`
  - Response: Success validation status.
- **Active Session Gate Toggles:**
  - `POST /api/v1/youtube/session/start` | `/stop`
  - Payload: `{"user_id": "uuid"}`
  - Response: Points balance and active limits trackers.

---

## 3. UI Component Registry (Flutter Client)

All widgets are declared inside `client/lib/presentation/widgets/` or plugins:

- **`YoutubeClientDashboard`:** Main screen presenting video search cards, local offline lists, and points metrics gauges.
- **`ActiveSessionTimerOverlay`:** Floating indicator overlay updating points costs and session locking notifications.
- **`DownloadedVideosList`:** Compact lists widget presenting cached local video rows and file size details.
