# What to Do | Maps & Live Tracking

This document outlines the development tasks and subagent assignments for implementing the Maps & Live Tracking telemetry infrastructure, providing geolocation tracking, private maps, and geofence controllers.

---

## 1. Subagent Alpha (Lead Architect) Commands
- [ ] **DATA_SCHEMAS.md Integration:** Update the system database layout in `vault/04 - LifeOS DevDocs/DATA_SCHEMAS.md` to define relational schemas for the `geofences`, `location_logs`, and `bookmarks` tables.
- [ ] **Point Star Reward Logic:** Define tracking rules for the Point Star System:
  - Add **+2 Star Points** to the user's ledger for logging custom geolocation tracks or coordinates reviews.
- [ ] **Conflict Resolution Specifications:** Define sync conflict schemas for parking records, ensuring Last-Write-Wins (LWW) resolution.
- [ ] **Milestone Logging:** Document all database schema updates, sync rules, and reward calculations in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) upon completion.

---

## 2. Subagent Beta (Frontend & Local Storage) Commands
- [ ] **Drift Table Generation:** Create Drift models inside `client/lib/database/` for:
  - `Geofences`: Fields for id, name, latitude, longitude, radius, is_active, is_dirty.
  - `LocationLogs`: Fields for id, device_id, latitude, longitude, timestamp, is_dirty.
  - `Bookmarks`: Fields for id, title, latitude, longitude, is_dirty.
  - Run database code generators to create matching DAOs and stream builders.
- [ ] **Radar Dashboard UI:** Build the location visualizer panel in `client/lib/presentation/widgets/` following the Everforest color scheme:
  - Scaffold screen canvas set to `EverforestColors.bg0`.
  - Maps detail cards and active metrics panels set to `EverforestColors.bg1`.
  - 1px thin outlines set to `EverforestColors.bg2` around each component card.
  - Custom typography using `EverforestColors.fg` for headers and `grey` for status labels.
- [ ] **OpenStreetMap View Integration:** Integrate offline mapping widgets rendering localized cache vectors and geofence circle overlays.
- [ ] **Change Documentation:** Update the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) with details of all new Drift tables, dynamic WebSocket listeners, and map trackers created.

---

## 3. Subagent Gamma (Systems, Security & Network) Commands
- [ ] **WebSocket Telemetry Streamer:** Write WebSocket routers in Go (`backend/host-daemon/internal/location/`) broadcasting client coordinates over the secure Tailnet bridge.
- [ ] **Geofence overlap checks:** Write spatial algorithms inside the server backend evaluating dynamic distance inputs to trigger webhooks.
- [ ] **REST API Sync Endpoints:** Register server handlers in the daemon configuration:
  - `GET /api/v1/radar/geofences`: List active geofence targets.
  - `POST /api/v1/radar/report`: Parse incoming background location parameters.
  - WebSocket `/api/v1/radar/live`: Secure coordinate stream.
- [ ] **Execution Log Update:** Record details of Go WebSockets, geofences overlap libraries, and offline map controllers in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) before final delivery.
