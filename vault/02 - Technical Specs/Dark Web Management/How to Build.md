# How to Build | Dark Web Management

This document outlines the step-by-step coding directives and architectural wiring instructions for developer subagents to implement the Dark Web Management system.

---

## 1. Step-by-Step Implementation Flow

### Step 1: Go Daemon P2P & ClamAV Integration (Subagent Gamma)
1. **Directory Allocation:** Create the module handlers in `backend/host-daemon/internal/darkweb/`.
2. **Transmission Wrapper:** Configure client connection wrappers using standard Unix/Windows RPC parameters:
   ```go
   func GetTorrentStatus(w http.ResponseWriter, r *http.Request) {
       // Invoke transmission-daemon RPC port
       status, err := queryTransmissionDaemon()
       if err != nil {
           http.Error(w, err.Error(), http.StatusInternalServerError)
           return
       }
       w.Header().Set("Content-Type", "application/json")
       json.NewEncoder(w).Encode(status)
   }
   ```
3. **Malware Sandbox Inspection:** Trigger ClamAV scanners on incoming binaries before storage relocation.

### Step 2: SQLite Drift Schema Migration (Subagent Beta)
1. **Table Mappings:** Add `TorrentsTable`, `TorrentPeersTable`, and `SharedFilesTable` class definitions in `client/lib/database/tables.dart`.
2. **SQLite Compilation:** Run code generator:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. **DAO Integration:** Define stream query providers returning active torrent seeds and transfer speeds.

### Step 3: Flutter Presentation UI (Subagent Beta)
1. **Everforest Colors:**
   - Canvas background: `EverforestColors.bg0`.
   - Cards and lists: `EverforestColors.bg1`.
   - Outlines and separators: 1px border lines in `EverforestColors.bg2`.
   - Text highlights: `EverforestColors.fg` (headers), `green` (complete/safe), `red` (infected/error).
2. **Interactive Console Layout:** Renders active download lists with seek control overlays, and list warning cards for quarantine items.

### Step 4: Star Point Hook (Subagent Alpha)
1. **Transaction Hooks:** Execute Points ledger transactions inside client updates:
   - Call `PointStarSystem.addPoints(1)` upon successful seeding of 1GB file size chunks.
   - Call `PointStarSystem.deductPoints(10)` if a quarantine scan flags a file as malicious.
2. **Sync Flag:** Mark mutated rows with `is_dirty = 1` to command immediate synchronization loops.
