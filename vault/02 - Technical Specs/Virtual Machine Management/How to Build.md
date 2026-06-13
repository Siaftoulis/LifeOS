# How to Build | Virtual Machine Management

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Virtual Machine Management|Virtual Machine Management]]



This document outlines the step-by-step coding directives and architectural wiring instructions for developer subagents to implement the Virtual Machine Management system.

---

## 1. Step-by-Step Implementation Flow

### Step 1: Go Daemon Firecracker/Docker CLI (Subagent Gamma)
1. **Directory Allocation:** Create the module handlers in `backend/host-daemon/internal/vm/`.
2. **Docker Shell Executor:** Implement control routines running terminal options:
   ```go
   func StartContainer(containerName string) error {
       cmd := exec.Command("docker", "start", containerName)
       return cmd.Run()
   }
   ```
3. **Tailscale Discovery Service:** Map peer listings parsing output from dynamic commands.

### Step 2: SQLite Drift Schema Migration (Subagent Beta)
1. **Table Mappings:** Add `VirtualMachinesTable` and `RemoteSessionsTable` definitions in `client/lib/database/tables.dart`.
2. **SQLite Compilation:** Run code generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. **DAO Integration:** Define database streams delivering running machines lists to the UI manager.

### Step 3: Flutter Status Cards UI (Subagent Beta)
1. **Everforest Colors:**
   - Scaffold canvas: `EverforestColors.bg0`.
   - Status panels: `EverforestColors.bg1`.
   - Outline separators: 1px border lines in `EverforestColors.bg2`.
   - Highlights: `EverforestColors.fg` (headers), `green` (active), `grey` (details).
2. **Remote Explorer List:** Build scrollable file directory explorer widgets.

### Step 4: System CPU/RAM Limits Handler (Subagent Alpha)
1. **Limits Builders:** Bind limits settings update updates inside client forms:
   - Call `VMManager.setLimits(cpuCount, ramMB)` on database actions.
2. **Sync Flags:** Set `is_dirty = 1` to command immediate synchronization loops.
