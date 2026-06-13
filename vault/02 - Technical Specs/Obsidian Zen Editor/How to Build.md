# How to Build | Obsidian Zen Editor

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Obsidian Zen Editor|Obsidian Zen Editor]]



This document outlines the step-by-step coding directives and architectural wiring instructions for developer subagents to implement the Obsidian Zen Editor.

---

## 1. Step-by-Step Implementation Flow

### Step 1: Go Daemon Collaborative Websocket Engine (Subagent Gamma)
1. **Directory Allocation:** Create the package in `backend/host-daemon/internal/markdown/`.
2. **WebSocket Text Broker:** Implement document modification broadcast controllers:
   ```go
   func HandleDocumentSync(w http.ResponseWriter, r *http.Request) {
       conn, err := upgrader.Upgrade(w, r, nil)
       if err != nil {
           log.Println("Upgrade failed:", err)
           return
       }
       // Read deltas and route modifications to concurrent active clients
       broadcastDeltas(conn)
   }
   ```
3. **Vault File Watcher:** Construct filesystem checkers scanning directory trees.

### Step 2: SQLite Drift Schema Migration (Subagent Beta)
1. **Table Mappings:** Add `MarkdownNotesTable` and `NotesIndexTable` definitions in `client/lib/database/tables.dart`.
2. **SQLite Compilation:** Run code generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. **DAO Integration:** Define select queries parsing note tag strings for custom lists dashboards.

### Step 3: Flutter Text Editing Viewport (Subagent Beta)
1. **Everforest Colors:**
   - Scaffold canvas: `EverforestColors.bg0`.
   - Text background: `EverforestColors.bg1`.
   - Outline separators: 1px border lines in `EverforestColors.bg2`.
   - Accents: `#fafafa` (reading text font).
2. **Focus Node Controllers:** Write UI components wrapping editing areas with focus fading triggers.

### Step 4: Star Points Logging Hook (Subagent Alpha)
1. **Time spent trackers:** Register background rules inside auto-saving handlers:
   - Calculate active typing durations. Call `PointStarSystem.addPoints(5)` per hour.
2. **Dirty Flags:** Mark mutated rows with `is_dirty = 1` to command immediate synchronization loops.
