# What to Build | Point Star System

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Point Star System|Point Star System]]



This document specifies the exact SQLite schemas, REST API paths, and Flutter widget components to build for the Point Star System.

---

## 1. Database Architecture (SQLite / Drift)

Four tables must be defined in the SQLite cache layer to support users balances, point configuration rules, history logs, and vouchers.

```sql
-- Schema for Users Points Registry
CREATE TABLE IF NOT EXISTS system_users (
    id TEXT PRIMARY KEY,
    username TEXT NOT NULL,
    current_points INTEGER DEFAULT 0,
    updated_at INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0
);

-- Schema for Points Rules Configuration
CREATE TABLE IF NOT EXISTS point_rules (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    module TEXT NOT NULL,
    points_value INTEGER NOT NULL, -- Positive for reward, negative for penalty
    is_dirty INTEGER DEFAULT 0
);

-- Schema for Points Ledger Logs
CREATE TABLE IF NOT EXISTS points_ledger (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    event TEXT NOT NULL,
    points INTEGER NOT NULL,
    timestamp INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0,
    FOREIGN KEY(user_id) REFERENCES system_users(id) ON DELETE CASCADE
);

-- Schema for Redeemable Vouchers Store
CREATE TABLE IF NOT EXISTS vouchers (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    cost_points INTEGER NOT NULL,
    is_redeemed INTEGER DEFAULT 0,
    redeemed_by TEXT,
    is_dirty INTEGER DEFAULT 0
);
```

---

## 2. API Specifications (Go Backend Daemon)

The host daemon manages transaction processing pipelines, updates user records, and issues webhooks.

### REST Endpoints
- **List Leaderboard Scores:**
  - `GET /api/v1/points/leaderboard`
  - Response: `JSON` array of users, names, and current balances.
- **Log Score Delta:**
  - `POST /api/v1/points/ledger`
  - Payload: `{"user_id": "uuid", "event": "habit_run", "points": 10}`
  - Response: Updated user points balance.
- **Redeem Store Voucher:**
  - `POST /api/v1/points/vouchers/redeem`
  - Payload: `{"voucher_id": "uuid", "user_id": "uuid"}`
  - Response: Redemption transaction details.

---

## 3. UI Component Registry (Flutter Client)

All widgets are declared inside `client/lib/presentation/widgets/` or plugins:

- **`PointStarDashboard`:** Main screen presenting users leaderboard, history log listings, and points status blocks.
- **`LeaderboardCard`:** Profile row displaying balances stats, neon progress metrics, and points counters.
- **`VoucherRedeemerPanel`:** Ticket-roll interface showing active vouchers, cost markers, and redeem toggles.
