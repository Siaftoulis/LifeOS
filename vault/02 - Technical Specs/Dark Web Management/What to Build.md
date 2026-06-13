# What to Build | Dark Web Management

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Dark Web Management|Dark Web Management]]



This document specifies the exact SQLite schemas, REST API paths, and Flutter widget components to build for the Dark Web Management system.

---

## 1. Database Architecture (SQLite / Drift)

Three tables must be defined in the SQLite cache layer to support P2P torrent downloads, active peers, and shared file audits.

```sql
-- Schema for Torrent Catalog
CREATE TABLE IF NOT EXISTS torrents (
    id TEXT PRIMARY KEY,
    info_hash TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    size_bytes INTEGER NOT NULL,
    progress REAL DEFAULT 0.0,
    download_speed INTEGER DEFAULT 0,
    upload_speed INTEGER DEFAULT 0,
    status TEXT NOT NULL,
    updated_at INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0
);

-- Schema for Torrent Active Peers
CREATE TABLE IF NOT EXISTS torrent_peers (
    id TEXT PRIMARY KEY,
    torrent_id TEXT NOT NULL,
    client_ip TEXT NOT NULL,
    bytes_exchanged INTEGER DEFAULT 0,
    is_dirty INTEGER DEFAULT 0,
    FOREIGN KEY(torrent_id) REFERENCES torrents(id) ON DELETE CASCADE
);

-- Schema for Shared and Quarantined Files
CREATE TABLE IF NOT EXISTS shared_files (
    id TEXT PRIMARY KEY,
    file_path TEXT NOT NULL,
    name TEXT NOT NULL,
    size_bytes INTEGER NOT NULL,
    status TEXT DEFAULT 'PENDING', -- 'PENDING', 'CLEAN', 'INFECTED'
    updated_at INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0
);
```

---

## 2. API Specifications (Go Backend Daemon)

The host daemon manages transmission-daemon hooks, runs ClamAV sanitization scans, and exposes status listings over secure Tailnet routes.

### REST Endpoints
- **List & Control Torrents:**
  - `GET /api/v1/darkweb/torrents`
  - Response: `JSON` list of active seeds, download metrics, and info_hashes.
- **Add Torrent Magnet Link:**
  - `POST /api/v1/darkweb/torrents/add`
  - Payload: `{"magnet_uri": "magnet:?xt=urn:btih:..."}`
  - Response: Created torrent meta information.
- **Quarantined File Promotion:**
  - `POST /api/v1/darkweb/promote`
  - Payload: `{"file_id": "uuid_string"}`
  - Response: Updated status and destination path.

---

## 3. UI Component Registry (Flutter Client)

All widgets are declared inside `client/lib/presentation/widgets/` or plugins:

- **`TorrentDashboardView`:** Main screen for torrent audits. Renders downloads list progress bars, seed ratio metrics, and peer counts.
- **`ActiveTorrentsList`:** Custom list view item presenting active/paused states, velocity badges (speeds), and deletion triggers.
- **`QuarantineWarningsPanel`:** High-contrast warnings console showing scan results, sandboxed runtime details, and safe database promotion buttons.
