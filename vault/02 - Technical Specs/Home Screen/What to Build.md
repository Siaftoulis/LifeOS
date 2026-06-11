# What to Build | Home Screen

This document specifies the exact SQLite schemas, REST API paths, and Flutter widget components to build for the Home Screen entry lock nexus.

---

## 1. Database Architecture (SQLite / Drift)

Two tables must be defined in the SQLite cache layer to support authentication controls, security attempt tracking, and notifications.

```sql
-- Schema for System User Credentials
CREATE TABLE IF NOT EXISTS system_user (
    id TEXT PRIMARY KEY,
    username TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    is_locked INTEGER DEFAULT 1,
    failed_attempts INTEGER DEFAULT 0,
    updated_at INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0
);

-- Schema for System Notifications Feed
CREATE TABLE IF NOT EXISTS local_notifications (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    category TEXT NOT NULL, -- 'SYSTEM', 'HABIT', 'SECURITY', 'FINANCIAL'
    read_at INTEGER, -- Timestamp or NULL
    created_at INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0
);
```

---

## 2. API Specifications (Go Backend Daemon)

The host daemon manages PIN verification pipelines, tracks security indicators, and exposes notifications filters.

### REST Endpoints
- **PIN Unlock Request:**
  - `POST /api/v1/auth/unlock`
  - Payload: `{"pin_hash": "raw_code_string"}`
  - Response:
    ```json
    {
      "authenticated": true,
      "token": "session_key_jwt",
      "role": "ADMIN"
    }
    ```
- **FCM Consolidated Dispatch:**
  - `POST /api/v1/auth/consolidate`
  - Response: Acknowledgment details.

---

## 3. UI Component Registry (Flutter Client)

All widgets are declared inside `client/lib/presentation/widgets/` or plugins:

- **`LockScreenOverlay`:** Full-screen lock display. Renders security PIN pad controls, dynamic time widgets, and notification timeline lists.
- **`ClockWidget`:** High-contrast time viewer adapting background wallpapers based on system theme configurations.
- **`ConsolidatedTaskFeedWidget`:** Central notifications tracker listing tasks, sync updates, and habit alerts in a compact list format.
