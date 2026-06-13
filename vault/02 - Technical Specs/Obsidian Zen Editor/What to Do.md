# What to Do | Obsidian Zen Editor

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Obsidian Zen Editor|Obsidian Zen Editor]]



This document outlines the development tasks and subagent assignments for implementing the Obsidian Zen Editor workspace, managing markdown files sync, collaborative routes, and metadata hooks.

---

## 1. Subagent Alpha (Lead Architect) Commands
- [ ] **DATA_SCHEMAS.md Integration:** Update the system database layout in `vault/04 - LifeOS DevDocs/DATA_SCHEMAS.md` to define relational schemas for the `markdown_notes` and `notes_index` tables.
- [ ] **Point Star Reward Logic:** Define tracking rules for the Point Star System:
  - Add **+5 Star Points** to the user's ledger for every hour of active note editing.
- [ ] **Conflict Resolution Specifications:** Define sync conflict schemas for Markdown files, using sequence-delta block CRDTs.
- [ ] **Milestone Logging:** Document all database schema updates, sync rules, and reward calculations in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) upon completion.

---

## 2. Subagent Beta (Frontend & Local Storage) Commands
- [ ] **Drift Table Generation:** Create Drift models inside `client/lib/database/` for:
  - `MarkdownNotes`: Fields for id, file_path, frontmatter_json, last_modified, hash, is_dirty.
  - `NotesIndex`: Fields for id, word_count, references_list, is_dirty.
  - Run database code generators to create matching DAOs and stream builders.
- [ ] **Editor Interface UI:** Build the focus-mode editor interface in `client/lib/presentation/widgets/` following the Everforest color scheme:
  - Scaffold screen canvas set to `EverforestColors.bg0`.
  - Notes grid cards and document edit panes set to `EverforestColors.bg1`.
  - 1px thin outlines set to `EverforestColors.bg2` around each component card.
  - Custom typography using `EverforestColors.fg` for headers and `grey` for status labels.
- [ ] **3D Graph Canvas Widget:** Build visual WebGL/Vector graph nodes displays highlighting notes connections.
- [ ] **Change Documentation:** Update the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) with details of all new Drift tables, markdown editors, and note link visualizers created.

---

## 3. Subagent Gamma (Systems, Security & Network) Commands
- [ ] **Collaborative WebSockets Server:** Write real-time collaborative text synchronizers in Go (`backend/host-daemon/internal/markdown/`) utilizing OT/CRDT algorithms.
- [ ] **File System Monitor:** Write folder watcher routines scanning local vault directories for markdown edits.
- [ ] **REST API Endpoints:** Register server handlers in the daemon configuration:
  - `POST /api/markdown/sync`: Handle atomic incoming markdown uploads.
  - `GET /api/markdown/history`: Query change logs lists.
  - WebSocket `/api/markdown/collab`: WebSocket interface handling concurrent editing keys.
- [ ] **Execution Log Update:** Record details of Go sync endpoints, collaborative WebSocket logs, and filesystem watch loops in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) before final delivery.

---

## 4. Absolute Perfection (Phase 2)
- [ ] **CRDT Implementation:** Upgrade the WebSocket echo server into a full Operational Transformation (OT) or Conflict-free Replicated Data Type (CRDT) engine to gracefully handle multi-device concurrent edits on the same file.
- [ ] **Native Filesystem Watcher:** Integrate `fsnotify` in `watcher.go` to directly monitor Obsidian's local folder for real-time changes and broadcast them to the Flutter client.
- [ ] **WebGL Physics Graph:** Upgrade `NotesGraphCanvas` from a standard 2D layout to a WebGL/Custom Physics engine to replicate the organic, spring-loaded node clustering seen in native Obsidian.
