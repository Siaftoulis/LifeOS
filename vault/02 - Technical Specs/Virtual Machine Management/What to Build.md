# What to Build | Virtual Machine Management

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Virtual Machine Management|Virtual Machine Management]]



This document specifies the exact SQLite schemas, REST API paths, and Flutter widget components to build for the Virtual Machine Management system.

---

## 1. Database Architecture (SQLite / Drift)

Two tables must be defined in the SQLite cache layer to support virtual workspace logs and active remote control streaming sessions.

```sql
-- Schema for Virtual Machines List
CREATE TABLE IF NOT EXISTS virtual_machines (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL, -- 'MICROVM', 'CONTAINER', 'DESKTOP'
    state TEXT NOT NULL, -- 'RUNNING', 'STOPPED', 'PAUSED'
    cpu_limit INTEGER DEFAULT 1,
    ram_limit INTEGER DEFAULT 512, -- in MB
    updated_at INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0
);

-- Schema for Remote Streaming Sessions
CREATE TABLE IF NOT EXISTS remote_sessions (
    id TEXT PRIMARY KEY,
    host_device TEXT NOT NULL,
    client_device TEXT NOT NULL,
    stream_port INTEGER NOT NULL,
    is_active INTEGER DEFAULT 1,
    is_dirty INTEGER DEFAULT 0
);
```

---

## 2. API Specifications (Go Backend Daemon)

The host daemon manages virtual environments lifecycle scripts, exposes node discovery metrics, and relays WebRTC channels.

### REST Endpoints
- **List & Control Instances:**
  - `GET /api/v1/vm`
  - Response: `JSON` list of local VMs, running ports, and usage parameters.
- **Toggle VM Execution:**
  - `POST /api/v1/vm/toggle`
  - Payload: `{"vm_id": "redroid_container", "action": "START"}`
  - Response: Updated execution status.
- **Explore Devices Files:**
  - `GET /api/v1/vm/explore?device_id={phone_id}&path={folder}`
  - Response: File directory JSON lists.

---

## 3. UI Component Registry (Flutter Client)

All widgets are declared inside `client/lib/presentation/widgets/` or plugins:

- **`VMManagementDashboard`:** Main screen presenting active virtual machines cards, system limits sliders, and active session controls.
- **`VMCondensedCard`:** Compact status panel showing visual indicators, neon state guides, and safety lock toggles.
- **`RemoteFileExplorerView`:** Explorer viewport rendering folder listings, navigation trails, and file transfer options.
