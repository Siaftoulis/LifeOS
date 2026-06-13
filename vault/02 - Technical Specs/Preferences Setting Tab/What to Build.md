# What to Build | Preferences Setting Tab

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Preferences Setting Tab|Preferences Setting Tab]]



This document specifies the exact SQLite schemas, REST API paths, and Flutter widget components to build for the Preferences Setting Tab system.

---

## 1. Database Architecture (SQLite / Drift)

Two tables must be defined in the SQLite cache layer to support global launcher configuration and profiles settings.

```sql
-- Schema for System Settings Key-Values
CREATE TABLE IF NOT EXISTS system_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0
);

-- Schema for System User Profiles
CREATE TABLE IF NOT EXISTS user_profiles (
    id TEXT PRIMARY KEY,
    username TEXT NOT NULL,
    role TEXT NOT NULL, -- 'ADMIN', 'NORMAL', 'CHILD'
    daily_limit INTEGER DEFAULT 0, -- Limit in minutes
    updated_at INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0
);
```

---

## 2. API Specifications (Go Backend Daemon)

The host daemon manages settings storage updates, parses Tailscale peer reports, and filters child lockouts.

### REST Endpoints
- **List & Control Settings:**
  - `GET /api/v1/system/settings`
  - Response: `JSON` list of key-value parameters.
- **Update System Settings:**
  - `POST /api/v1/system/settings`
  - Payload: `{"key": "oled_black", "value": "true"}`
  - Response: Status confirmation.
- **Tailscale Active Nodes:**
  - `GET /api/v1/system/nodes`
  - Response: JSON list of peer devices IP addresses and metadata.

---

## 3. UI Component Registry (Flutter Client)

All widgets are declared inside `client/lib/presentation/widgets/` or plugins:

- **`PreferencesDashboardView`:** Main screen presenting launcher configuration settings and user profiles editors.
- **`GridConfiguratorWidget`:** Interactive drag grid providing visual controls to organize the 3x3 layout.
- **`TailscaleNodeMonitorWidget`:** Details grid displaying dynamic lists of connected network items.
