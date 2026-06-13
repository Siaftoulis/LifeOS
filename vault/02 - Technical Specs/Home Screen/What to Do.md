# What to Do | Home Screen

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Home Screen|Home Screen]]



This document outlines the development tasks and subagent assignments for implementing the Home Screen launcher nexus, managing client locks, security checks, and notification feeds.

---

## 1. Subagent Alpha (Lead Architect) Commands
- [ ] **DATA_SCHEMAS.md Integration:** Update the system database layout in `vault/04 - LifeOS DevDocs/DATA_SCHEMAS.md` to define relational schemas for the `system_user` and `local_notifications` tables.
- [ ] **Point Star Reward Logic:** Map connection checkpoints to reward systems (such as daily active checks).
- [ ] **Conflict Resolution Specifications:** Define sync conflict schemas for locked security profiles, ensuring server-authoritative LWW resolution.
- [ ] **Milestone Logging:** Document all database schema updates, sync rules, and reward calculations in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) upon completion.

---

## 2. Subagent Beta (Frontend & Local Storage) Commands
- [ ] **Drift Table Generation:** Create Drift models inside `client/lib/database/` for:
  - `SystemUser`: Fields for id, username, password_hash, is_locked, failed_attempts, is_dirty.
  - `LocalNotifications`: Fields for id, title, message, category, read_at, created_at, is_dirty.
  - Run database code generators to create matching DAOs and stream builders.
- [ ] **Lock Screen View:** Build the secure lock overlay interface in `client/lib/presentation/widgets/` following the Everforest color scheme:
  - Scaffold screen canvas set to `EverforestColors.bg0`.
  - Security keypad and details panels set to `EverforestColors.bg1`.
  - 1px thin outlines set to `EverforestColors.bg2` around each component card.
  - Custom typography using `EverforestColors.fg` for headers and `grey` for date/notification details.
- [ ] **Keypad Unlock Panel:** Build PIN entry grids returning stateful lock feedback events.
- [ ] **Change Documentation:** Update the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) with details of all new Drift tables, Clock layout stubs, and local notification alerts.

---

## 3. Subagent Gamma (Systems, Security & Network) Commands
- [ ] **Authentication API Handler:** Write authentication check endpoints in Go (`backend/host-daemon/internal/auth/`) using secure hashing engines (such as bcrypt) to evaluate PIN codes.
- [ ] **Centrality Algorithm Configuration:** Configure spatial grid calculations to automatically bind the launcher dashboard directly to the center index coordinate (e.g. `[1,1]`).
- [ ] **REST API Endpoints:** Register server handlers in the daemon configuration:
  - `POST /api/v1/auth/unlock`: Validate incoming user credentials.
  - `POST /api/v1/auth/lock`: Set locked status flags.
  - `GET /api/v1/notifications`: List pending system alerts.
- [ ] **Execution Log Update:** Record details of Go authentication, central location layout math, and push notifications in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) before final delivery.
