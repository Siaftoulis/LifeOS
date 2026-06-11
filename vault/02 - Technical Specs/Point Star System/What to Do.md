# What to Do | Point Star System

This document outlines the development tasks and subagent assignments for implementing the Point Star System behavioral ledger, gamification rules, and TV lock triggers.

---

## 1. Subagent Alpha (Lead Architect) Commands
- [ ] **DATA_SCHEMAS.md Integration:** Update the system database layout in `vault/04 - LifeOS DevDocs/DATA_SCHEMAS.md` to define relational schemas for the `system_users`, `point_rules`, `points_ledger`, and `vouchers` tables.
- [ ] **Point Star Reward Logic:** Define base rules configuration and point triggers.
- [ ] **Conflict Resolution Specifications:** Define sync conflict schemas for user balance totals, ensuring server-authoritative LWW resolution.
- [ ] **Milestone Logging:** Document all database schema updates, sync rules, and reward calculations in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) upon completion.

---

## 2. Subagent Beta (Frontend & Local Storage) Commands
- [ ] **Drift Table Generation:** Create Drift models inside `client/lib/database/` for:
  - `SystemUsers`: Fields for id, username, current_points, is_dirty.
  - `PointRules`: Fields for id, name, module, points_value, is_dirty.
  - `PointsLedger`: Fields for id, user_id, event, points, timestamp, is_dirty.
  - `Vouchers`: Fields for id, title, cost_points, is_redeemed, is_dirty.
  - Run database code generators to create matching DAOs and stream builders.
- [ ] **Leaderboard Dashboard UI:** Build the family ledger screens in `client/lib/presentation/widgets/` following the Everforest color scheme:
  - Scaffold screen canvas set to `EverforestColors.bg0`.
  - Profile cards and lists items set to `EverforestColors.bg1`.
  - 1px thin outlines set to `EverforestColors.bg2` around each component card.
  - Custom typography using `EverforestColors.fg` for headers and `grey` for status labels.
- [ ] **Redeem Vouchers Grid:** Build the vouchers display page showing ticket layouts and redemption switch toggles.
- [ ] **Change Documentation:** Update the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) with details of all new Drift tables, Leaderboard lists, and vouchers store views created.

---

## 3. Subagent Gamma (Systems, Security & Network) Commands
- [ ] **Points Rule Engine:** Write transaction handlers in Go (`backend/host-daemon/internal/points/`) processing balance changes securely.
- [ ] **Appliance Lock Webhooks:** Write background trigger services executing smart home API lock commands when stars drop below limits.
- [ ] **REST API Endpoints:** Register server handlers in the daemon configuration:
  - `GET /api/v1/points/leaderboard`: List active user scores.
  - `POST /api/v1/points/ledger`: Add entries to the scores history.
  - `POST /api/v1/points/vouchers/redeem`: Log voucher redemption transactions.
- [ ] **Execution Log Update:** Record details of Go rule checkers and smart TV API controllers in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) before final delivery.
