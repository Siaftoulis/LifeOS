# What to Do | Home Management

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Home Management|Home Management]]



This document outlines the development tasks and subagent assignments for implementing the Home Management system, providing integration to local smart devices and automatic geofence controllers.

---

## 1. Subagent Alpha (Lead Architect) Commands
- [ ] **DATA_SCHEMAS.md Integration:** Update the system database layout in `vault/04 - LifeOS DevDocs/DATA_SCHEMAS.md` to define relational schemas for the `smart_devices`, `environment_logs`, and `device_schedules` tables.
- [ ] **Point Star Reward Logic:** Define tracking rules for the Point Star System:
  - Add **+1 Star Point** to the user's ledger for every day the smart devices run within designated energy thresholds.
- [ ] **Conflict Resolution Specifications:** Define sync conflict schemas for smart device toggle values, ensuring Last-Write-Wins (LWW) resolution.
- [ ] **Milestone Logging:** Document all database schema updates, sync rules, and reward calculations in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) upon completion.

---

## 2. Subagent Beta (Frontend & Local Storage) Commands
- [ ] **Drift Table Generation:** Create Drift models inside `client/lib/database/` for:
  - `SmartDevices`: Fields for id, name, type, state, room, last_updated, is_dirty.
  - `EnvironmentLogs`: Fields for id, sensor_id, temperature, humidity, timestamp, is_dirty.
  - `DeviceSchedules`: Fields for id, device_id, action, cron_expression, is_dirty.
  - Run database code generators to create matching DAOs and stream builders.
- [ ] **Home Dashboard UI:** Build the smart devices grid interface in `client/lib/presentation/widgets/` following the Everforest color scheme:
  - Scaffold screen canvas set to `EverforestColors.bg0`.
  - Toggle grids and sensor cards set to `EverforestColors.bg1`.
  - 1px thin outlines set to `EverforestColors.bg2` around each component card.
  - Custom typography using `EverforestColors.fg` for headers and `grey` for status/telemetry details.
- [ ] **Smart Toggles Grid:** Build responsive grids of toggle switches indicating device states and local temperature readings.
- [ ] **Change Documentation:** Update the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) with details of all new Drift tables, Smart toggles, and sensor timeline log views.

---

## 3. Subagent Gamma (Systems, Security & Network) Commands
- [ ] **Home Assistant WebSockets:** Write WebSocket connection handlers in Go (`backend/host-daemon/internal/home/`) to establish links to the local Home Assistant server.
- [ ] **Raspberry Pi Telemetry Interface:** Write lightweight telemetry collection nodes to parse incoming sensor signals from remote Raspberry Pi devices.
- [ ] **REST API Endpoints:** Register server handlers in the daemon configuration:
  - `GET /api/v1/home/devices`: Retrieve active smart device list.
  - `POST /api/v1/home/devices/toggle`: Toggle states of light/power systems.
  - `POST /api/v1/home/sensors/report`: Endpoint for Raspberry Pi nodes to upload climate telemetry.
- [ ] **Execution Log Update:** Record details of Home Assistant connection scripts and sensor nodes in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) before final delivery.
