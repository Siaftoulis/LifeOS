# How to Build | Point Star System

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Point Star System|Point Star System]]



This document outlines the step-by-step coding directives and architectural wiring instructions for developer subagents to implement the Point Star System.

---

## 1. Step-by-Step Implementation Flow

### Step 1: Go Daemon Rules Processor (Subagent Gamma)
1. **Directory Allocation:** Create the module package in `backend/host-daemon/internal/points/`.
2. **Points Ledger Updates:** Implement transaction handlers processing balances changes:
   ```go
   func ApplyPointsChange(userID string, delta int) (int, error) {
       // Execute SQL transaction modifying user points totals
       return updateUserPoints(userID, delta)
   }
   ```
3. **Privilege Lockout Checks:** Monitor user limits triggers to lock entertainment access keys.

### Step 2: SQLite Drift Schema Migration (Subagent Beta)
1. **Table Mappings:** Add `SystemUsersTable`, `PointRulesTable`, `PointsLedgerTable`, and `VouchersTable` class definitions in `client/lib/database/tables.dart`.
2. **SQLite Compilation:** Run code generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. **DAO Integration:** Define stream query providers returning scores history logs.

### Step 3: Flutter Leaderboard UI (Subagent Beta)
1. **Everforest Colors:**
   - Scaffold canvas: `EverforestColors.bg0`.
   - Grid cards: `EverforestColors.bg1`.
   - Outline separators: 1px border lines in `EverforestColors.bg2`.
   - Text highlights: `EverforestColors.fg` (headers), `grey` (details).
2. **Vouchers Store Page:** Build dynamic grids rendering ticket vouchers lists.

### Step 4: Points Rule Configurations Interface (Subagent Alpha)
1. **Rules Builders:** Build UI options allowing new rules definitions:
   - Configure dynamic points multipliers inside target modules lists.
2. **Sync Flags:** Set `is_dirty = 1` to command immediate synchronization loops.
