# How to Build | Home Management

This document outlines the step-by-step coding directives and architectural wiring instructions for developer subagents to implement the Home Management system.

---

## 1. Step-by-Step Implementation Flow

### Step 1: Go Daemon HA WebSocket & Sensor Links (Subagent Gamma)
1. **Directory Allocation:** Create the module package in `backend/host-daemon/internal/home/`.
2. **WebSocket Client:** Implement persistent connection logic to the Home Assistant instance:
   ```go
   func ConnectHomeAssistant(uri string, token string) (*websocket.Conn, error) {
       headers := http.Header{}
       headers.Add("Authorization", "Bearer " + token)
       conn, _, err := websocket.DefaultDialer.Dial(uri, headers)
       return conn, err
   }
   ```
3. **Sensor Node Receiver:** Create HTTP endpoints parsing JSON packets from remote temperature indicators.

### Step 2: SQLite Drift Schema Migration (Subagent Beta)
1. **Table Mappings:** Add `SmartDevicesTable`, `EnvironmentLogsTable`, and `DeviceSchedulesTable` definitions in `client/lib/database/tables.dart`.
2. **SQLite Compilation:** Run code generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. **DAO Integration:** Define query builders mapping live status states for active UI components.

### Step 3: Flutter Toggle Grid UI (Subagent Beta)
1. **Everforest Colors:**
   - Scaffold canvas: `EverforestColors.bg0`.
   - Grid toggles: `EverforestColors.bg1`.
   - Outline separators: 1px borders in `EverforestColors.bg2`.
   - Accents: `EverforestColors.fg` (headers), `green` (ON state), `grey` (OFF state).
2. **Grid Toggles Widgets:** Build horizontal grids containing switch widgets with fast-tap gesture responses.

### Step 4: Proximity Trigger Setup (Subagent Alpha)
1. **Automation Links:** Intercept locations checks inside server synchronization routines:
   - Calculate user coordinates in relation to Home boundaries.
   - If distance drops below 1km, fire automation payloads to trigger kitchen appliances.
2. **Sync Mark:** Set `is_dirty = 1` to command immediate synchronization loops.
