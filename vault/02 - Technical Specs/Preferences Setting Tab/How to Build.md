# How to Build | Preferences Setting Tab

This document outlines the step-by-step coding directives and architectural wiring instructions for developer subagents to implement the Preferences Setting Tab.

---

## 1. Step-by-Step Implementation Flow

### Step 1: Go Daemon Settings & Node Crawler (Subagent Gamma)
1. **Directory Allocation:** Create the package in `backend/host-daemon/internal/system/`.
2. **Tailscale Node Monitor:** Implement peer info collection services checking active connection states:
   ```go
   func QueryTailscaleNodes() ([]Node, error) {
       // Invoke local CLI command to extract peers status lists
       cmd := exec.Command("tailscale", "status", "--json")
       return parseNodesOutput(cmd)
   }
   ```
3. **Profile Filters:** Implement routes hiding VM and Torrent tabs on child user profiles.

### Step 2: SQLite Drift Schema Migration (Subagent Beta)
1. **Table Mappings:** Add `SystemSettingsTable` and `UserProfilesTable` definitions in `client/lib/database/tables.dart`.
2. **SQLite Compilation:** Run code generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. **DAO Integration:** Define queries mapping config items to the local PreferencesService cache.

### Step 3: Flutter Grid Configurator UI (Subagent Beta)
1. **Everforest Colors:**
   - Scaffold canvas: `EverforestColors.bg0`.
   - Settings lists: `EverforestColors.bg1`.
   - Outline separators: 1px border lines in `EverforestColors.bg2`.
   - Text highlights: `EverforestColors.fg` (headers), `grey` (details).
2. **Dynamic Drag Grid:** Build modular grid list items allowing drag-and-drop module coordinates swap.

### Step 4: Child Profile Lockout Hook (Subagent Alpha)
1. **Lockout Controls:** Bind profile settings validation to route filters:
   - Disable administrative tabs when role value equals child tags.
2. **Sync Flags:** Set `is_dirty = 1` to command immediate synchronization loops.
