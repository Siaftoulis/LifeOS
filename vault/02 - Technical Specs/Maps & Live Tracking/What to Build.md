# What to Build | Maps & Live Tracking

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Maps & Live Tracking|Maps & Live Tracking]]



This document specifies the exact SQLite schemas, REST API paths, and Flutter widget components to build for the Maps & Live Tracking system.

---

## 1. Database Architecture (SQLite / Drift)

Three tables must be defined in the SQLite cache layer to support geofencing parameters, telemetry trails, and custom bookmark vectors.

```sql
-- Schema for Geofencing Regions
CREATE TABLE IF NOT EXISTS geofences (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    radius REAL NOT NULL, -- radius in meters
    is_active INTEGER DEFAULT 1,
    updated_at INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0
);

-- Schema for Telemetry Coordinates Logs
CREATE TABLE IF NOT EXISTS location_logs (
    id TEXT PRIMARY KEY,
    device_id TEXT NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    velocity REAL,
    altitude REAL,
    timestamp INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0
);

-- Schema for Private Bookmarked Coordinates
CREATE TABLE IF NOT EXISTS bookmarks (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    created_at INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0
);
```

---

## 2. API Specifications (Go Backend Daemon)

The host daemon parses background coordinate updates, processes WebSocket relays, and triggers smart home webhooks.

### REST Endpoints
- **List & Control Geofences:**
  - `GET /api/v1/radar/geofences`
  - Response: `JSON` list of active zones and circular metrics coordinates.
- **WebSocket Coordinates Interface:**
  - `WS /api/v1/radar/live`
  - Format: Real-time JSON coordinates streams from client GPS nodes.
- **Background Reporting Link:**
  - `POST /api/v1/radar/report`
  - Payload: `{"device_id": "mobile_phone", "latitude": 37.98, "longitude": 23.72}`
  - Response: Triggered automation details.

---

## 3. UI Component Registry (Flutter Client)

All widgets are declared inside `client/lib/presentation/widgets/` or plugins:

- **`DarkRadarWidget`:** Custom maps panel rendering real-time sweeps of client nodes and coordinate bookmarks.
- **`MapsDashboardWidget`:** Central maps viewport integrating vector packages and offline overlays.
- **`GeofenceEditorWidget`:** Dynamic editor panel providing touch inputs to modify circular boundaries and labels.
