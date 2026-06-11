# What to Do | Preferences Setting Tab

This document outlines the development tasks and subagent assignments for implementing the Preferences Setting Tab system, managing system parameters, profiles, and networking status logs.

---

## 1. Subagent Alpha (Lead Architect) Commands
- [ ] **DATA_SCHEMAS.md Integration:** Update the system database layout in `vault/04 - LifeOS DevDocs/DATA_SCHEMAS.md` to define relational schemas for the `system_settings` and `user_profiles` tables.
- [ ] **Point Star Reward Logic:** Define active checkpoints to lock dashboard features when child profiles balances drop below thresholds.
- [ ] **Conflict Resolution Specifications:** Define sync conflict schemas for settings lists, ensuring client-driven Last-Write-Wins (LWW) resolution.
- [ ] **Milestone Logging:** Document all database schema updates, sync rules, and reward calculations in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) upon completion.

---

## 2. Subagent Beta (Frontend & Local Storage) Commands
- [ ] **Drift Table Generation:** Create Drift models inside `client/lib/database/` for:
  - `SystemSettings`: Fields for key, value, updated_at, is_dirty.
  - `UserProfiles`: Fields for id, username, role, daily_limit, is_dirty.
  - Run database code generators to create matching DAOs and stream builders.
- [ ] **Settings Interface UI:** Build the launcher configurator screen in `client/lib/presentation/widgets/` following the Everforest color scheme:
  - Scaffold screen canvas set to `EverforestColors.bg0`.
  - Config lists and grid grids set to `EverforestColors.bg1`.
  - 1px thin outlines set to `EverforestColors.bg2` around each component card.
  - Custom typography using `EverforestColors.fg` for headers and `grey` for detail labels.
- [ ] **Dynamic Grid Editor Widget:** Build visual drag-and-drop tiles rearrangement viewports.
- [ ] **Change Documentation:** Update the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) with details of all new Drift tables, Settings items, and system dashboard nodes trackers.

---

## 3. Subagent Gamma (Systems, Security & Network) Commands
- [ ] **Tailscale Node Crawler:** Write status API scanners in Go (`backend/host-daemon/internal/system/`) monitoring active Tailscale mesh devices.
- [ ] **Child Lock Filters:** Write Go routines checking user profiles configurations to block system settings pages on child profiles.
- [ ] **REST API Endpoints:** Register server handlers in the daemon configuration:
  - `GET /api/v1/system/settings`: Retrieve settings variables list.
  - `POST /api/v1/system/settings`: Update settings database.
  - `GET /api/v1/system/nodes`: List active connected nodes profiles.
- [ ] **Execution Log Update:** Record details of Go setting controls, user profile models, and Tailscale crawlers in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) before final delivery.
