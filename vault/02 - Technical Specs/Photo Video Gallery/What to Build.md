# What to Build | Photo Video Gallery

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Photo Video Gallery|Photo Video Gallery]]



This document specifies the exact SQLite schemas, REST API paths, and Flutter widget components to build for the Photo Video Gallery asset manager.

---

## 1. Database Architecture (SQLite / Drift)

Two tables must be defined in the SQLite cache layer to support media file cataloging, classification, and geo-coordinates tags.

```sql
-- Schema for Media Assets Inventory
CREATE TABLE IF NOT EXISTS media_assets (
    id TEXT PRIMARY KEY,
    filename TEXT NOT NULL,
    file_path TEXT NOT NULL UNIQUE,
    file_size INTEGER NOT NULL,
    file_type TEXT NOT NULL, -- 'PHOTO', 'VIDEO'
    latitude REAL,
    longitude REAL,
    capture_time INTEGER NOT NULL, -- Unix timestamp
    scan_status TEXT DEFAULT 'PENDING',
    updated_at INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0
);

-- Schema for Assets Categories Tags
CREATE TABLE IF NOT EXISTS media_tags (
    id TEXT PRIMARY KEY,
    asset_id TEXT NOT NULL,
    tag_name TEXT NOT NULL,
    tag_type TEXT NOT NULL, -- 'FACE', 'SCENE', 'MANUAL'
    confidence REAL DEFAULT 1.0,
    is_dirty INTEGER DEFAULT 0,
    FOREIGN KEY(asset_id) REFERENCES media_assets(id) ON DELETE CASCADE
);
```

---

## 2. API Specifications (Go Backend Daemon)

The host daemon manages upload storage folders, converts image formats, and parses metadata tags.

### REST Endpoints
- **Upload Media Asset:**
  - `POST /api/v1/gallery/upload`
  - Payload: Multipart file stream.
  - Response: Created media item properties.
- **Get Thumbnail Cache:**
  - `GET /api/v1/gallery/thumbnail?id={asset_id}`
  - Response: Transcoded WebP image binaries.
- **Serve Dynamic Streams:**
  - `GET /api/v1/gallery/stream?id={asset_id}`
  - Headers: Supports byte range headers.
  - Response: Video binary chunk streams.

---

## 3. UI Component Registry (Flutter Client)

All widgets are declared inside `client/lib/presentation/widgets/` or plugins:

- **`GalleryGridWidget`:** Main interface rendering album lists and photo grid cards.
- **`PhotoDetailScreen`:** Fullscreen display supporting gesture swipes and EXIF data summaries.
- **`BackupActivityPanel`:** Settings overlay listing active camera-roll uploads and progress bar schedules.
