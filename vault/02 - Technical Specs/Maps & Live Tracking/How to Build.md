# How to Build | Maps & Live Tracking

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Maps & Live Tracking|Maps & Live Tracking]]



This document outlines the step-by-step coding directives and architectural wiring instructions for developer subagents to implement the Maps & Live Tracking system.

---

## 1. Step-by-Step Implementation Flow

### Step 1: Go Daemon WebSocket & Geofence Checks (Subagent Gamma)
1. **Directory Allocation:** Create the module routers in `backend/host-daemon/internal/location/`.
2. **WebSocket Broker:** Implement live coordinate streaming relays using WebSocket clients:
   ```go
   func HandleLocationStream(w http.ResponseWriter, r *http.Request) {
       conn, err := upgrader.Upgrade(w, r, nil)
       if err != nil {
           log.Println("Upgrade failed:", err)
           return
       }
       // Read GPS coordinates and broadcast to active Tailnet listeners
       broadcastCoordinates(conn)
   }
   ```
3. **Range Check Logic:** Implement mathematical distance evaluations triggering Home Assistant locks.

### Step 2: SQLite Drift Schema Migration (Subagent Beta)
1. **Table Mappings:** Add `GeofencesTable`, `LocationLogsTable`, and `BookmarksTable` class declarations in `client/lib/database/tables.dart`.
2. **SQLite Compilation:** Run code generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. **DAO Integration:** Define queries returning last logged locations for target tracker nodes.

### Step 3: Flutter Radar Overlay UI (Subagent Beta)
1. **Everforest Colors:**
   - Scaffold canvas: `EverforestColors.bg0`.
   - Details display: `EverforestColors.bg1`.
   - Outline separators: 1px border lines in `EverforestColors.bg2`.
   - Highlight signals: `cyan` (live radar beacons), `grey` (labels).
2. **Radar Sweeps Layout:** Build custom canvas overlays animating grid loops using coordinate maps.

### Step 4: Automation Webhooks Hook (Subagent Alpha)
1. **Trigger payloads:** Wire location checks to fire external payloads:
   - Call `HomeAutomation.triggerZoneArrival()` when boundaries intersect.
2. **Sync Flags:** Mark mutated rows with `is_dirty = 1` to command immediate synchronization loops.
