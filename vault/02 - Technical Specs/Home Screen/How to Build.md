# How to Build | Home Screen

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Home Screen|Home Screen]]



This document outlines the step-by-step coding directives and architectural wiring instructions for developer subagents to implement the Home Screen launcher.

---

## 1. Step-by-Step Implementation Flow

### Step 1: Go Daemon Bcrypt Authentication (Subagent Gamma)
1. **Directory Allocation:** Create the module package in `backend/host-daemon/internal/auth/`.
2. **PIN Hashing Checker:** Implement safe password hashing routines inside API targets:
   ```go
   func AuthenticatePIN(storedHash string, inputPIN string) bool {
       err := bcrypt.CompareHashAndPassword([]byte(storedHash), []byte(inputPIN))
       return err == nil
   }
   ```
3. **Session Verification:** Generate lightweight JWT session identifiers upon successful validation.

### Step 2: SQLite Drift Schema Migration (Subagent Beta)
1. **Table Mappings:** Add `SystemUserTable` and `LocalNotificationsTable` declarations in `client/lib/database/tables.dart`.
2. **SQLite Compilation:** Run code generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. **DAO Integration:** Define reactive queries supplying current lock states to the primary route manager.

### Step 3: Flutter Security Keypad UI (Subagent Beta)
1. **Everforest Colors:**
   - Scaffold canvas: `EverforestColors.bg0`.
   - Keypad buttons: `EverforestColors.bg1`.
   - Outlines: 1px border lines in `EverforestColors.bg2`.
   - Accents: `EverforestColors.fg` (headers), `grey` (labels).
2. **Lock Keypad Grid:** Build digit grids capturing input integers, firing authentication triggers upon entry vectors.

### Step 4: Spatial Engine Calibration (Subagent Alpha)
1. **Launcher Centering:** Configure startup layout math to automatically anchor the dashboard specifically to center indices (e.g. `[1,1]`).
2. **Dirty Flags:** Mark mutated rows with `is_dirty = 1` to command immediate synchronization loops.
