# What to Build | Cloud & Fake Virtual Machine

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Cloud & Fake Virtual Machine|Cloud & Fake Virtual Machine]]



This document specifies the exact SQLite schemas, REST API paths, and Flutter widget components to build for the Cloud & Fake Virtual Machine system.

---

## 1. Database Architecture (SQLite / Drift)

Three tables must be defined in the SQLite cache layer to support automated backups, historical logs, and uploaded file quarantine:

```sql
-- Schema for Device Backups
CREATE TABLE IF NOT EXISTS device_backups (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,                -- e.g. 'Laptop-Panos'
    last_backup INTEGER NOT NULL,      -- Unix millisecond timestamp
    storage_path TEXT NOT NULL,        -- Relative local server backup path
    backup_status TEXT NOT NULL,       -- 'PENDING', 'ACTIVE', 'COMPLETED', 'FAILED'
    updated_at INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0
);

-- Schema for Backup History Logs
CREATE TABLE IF NOT EXISTS backup_logs (
    log_id TEXT PRIMARY KEY,
    device_id TEXT NOT NULL,
    timestamp INTEGER NOT NULL,        -- Unix millisecond timestamp
    files_count INTEGER NOT NULL,
    bytes_transferred INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0,
    FOREIGN KEY(device_id) REFERENCES device_backups(id) ON DELETE CASCADE
);

-- Schema for Quarantine Uploads
CREATE TABLE IF NOT EXISTS upload_quarantine (
    file_id TEXT PRIMARY KEY,
    file_name TEXT NOT NULL,
    file_size INTEGER NOT NULL,
    scan_status TEXT DEFAULT 'PENDING', -- 'PENDING', 'CLEAN', 'INFECTED'
    created_at INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0
);
```

---

## 2. API Specifications (Go Backend Daemon)

The host daemon handles scheduled backup scripts, serves the lightweight Web OS reader, and runs ClamAV sanitization filters.

### REST Endpoints
- **List Backup Profiles:**
  - `GET /api/v1/cloud/backups`
  - Response: `JSON` list of registered device profiles and backup schedules.
- **File Upload & Malware Inspection:**
  - `POST /api/v1/cloud/upload`
  - Payload: File byte array stream.
  - Operations: Saves file to `temp/`, triggers `clamdscan` binary check.
  - Response:
    ```json
    {
      "file_id": "uuid_string",
      "file_name": "backup.zip",
      "scan_status": "CLEAN"
    }
    ```
- **Web OS Dashboard Viewer:**
  - `GET /api/v1/cloud/web-os`
  - Headers: Enforces `Clear-Site-Data: "cache", "cookies", "storage"` to wipe browser forensics.
  - Response: Serves static HTML/React/Flutter Web client bundle.

---

## 3. UI Component Registry (Flutter Client)

All widgets are declared inside `client/lib/presentation/widgets/` or plugins:

- **`CloudBackupDashboard`:** Main module screen. Renders registered devices bookshelf style cards, active backup execution states, and sync schedule triggers.
- **`BackupStatusList`:** Vertical timeline view showing historical backup files count, data volume sizes, and completion markers.
- **`QuarantineView`:** Security check tab displaying real-time scan statuses of recently uploaded files (cleaning animations for PENDING, threat warnings for INFECTED).
