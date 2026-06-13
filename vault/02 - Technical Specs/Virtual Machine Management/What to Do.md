# What to Do | Virtual Machine Management

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Virtual Machine Management|Virtual Machine Management]]



This document outlines the development tasks and subagent assignments for implementing the Virtual Machine Management virtualization interface, remote screen streamers, and file explorer bridges.

---

## 1. Subagent Alpha (Lead Architect) Commands
- [ ] **DATA_SCHEMAS.md Integration:** Update the system database layout in `vault/04 - LifeOS DevDocs/DATA_SCHEMAS.md` to define relational schemas for the `virtual_machines` and `remote_sessions` tables.
- [ ] **Point Star Reward Logic:** Map connection checkpoints to reward systems (such as system uptime logs).
- [ ] **Conflict Resolution Specifications:** Define sync conflict schemas for active VM states, ensuring server-authoritative LWW resolution.
- [ ] **Milestone Logging:** Document all database schema updates, sync rules, and reward calculations in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) upon completion.

---

## 2. Subagent Beta (Frontend & Local Storage) Commands
- [ ] **Drift Table Generation:** Create Drift models inside `client/lib/database/` for:
  - `VirtualMachines`: Fields for id, name, type, state, cpu_limit, ram_limit, is_dirty.
  - `RemoteSessions`: Fields for id, host_device, client_device, stream_port, is_active, is_dirty.
  - Run database code generators to create matching DAOs and stream builders.
- [ ] **VM Dashboard UI:** Build the active machines management view in `client/lib/presentation/widgets/` following the Everforest color scheme:
  - Scaffold screen canvas set to `EverforestColors.bg0`.
  - Machine status cards and terminal consoles set to `EverforestColors.bg1`.
  - 1px thin outlines set to `EverforestColors.bg2` around each component card.
  - Custom typography using `EverforestColors.fg` for headers and `grey` for status labels.
- [ ] **Remote Explorer Panel:** Build visual file explorer views presenting folder pathways and transfer progress bars.
- [ ] **Change Documentation:** Update the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) with details of all new Drift tables, VM status switches, and Remote File views created.

---

## 3. Subagent Gamma (Systems, Security & Network) Commands
- [ ] **Docker/Firecracker CLI Wrappers:** Write Docker shell interfaces in Go (`backend/host-daemon/internal/vm/`) to initialize, monitor, and destroy virtual workspaces.
- [ ] **Tailscale Node Discovery:** Configure node check scripts mapping Tailnet peer capabilities.
- [ ] **REST API Endpoints:** Register server handlers in the daemon configuration:
  - `GET /api/v1/vm`: List active virtual machines and statuses.
  - `POST /api/v1/vm/toggle`: Toggle states of running instances.
  - `GET /api/v1/vm/discovery`: List discoverable Tailscale nodes.
- [ ] **Execution Log Update:** Record details of Go VM executors, Tailscale discovery managers, and WebRTC streaming modules in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) before final delivery.
