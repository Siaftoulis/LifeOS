# What to Do | Project Infinity

This document outlines the development tasks and subagent assignments for implementing the Project Infinity vocabulary system, daily learning logs, and flashcard integrations.

---

## 1. Subagent Alpha (Lead Architect) Commands
- [ ] **DATA_SCHEMAS.md Integration:** Update the system database layout in `vault/04 - LifeOS DevDocs/DATA_SCHEMAS.md` to define relational schemas for the `daily_words` and `daily_trivia` tables.
- [ ] **Point Star Reward Logic:** Define tracking rules for the Point Star System:
  - Add **+1 Star Point** to the user's ledger for reviewing daily words.
  - Add **+2 Star Points** for completing daily trivia entry notes.
- [ ] **Conflict Resolution Specifications:** Define sync conflict schemas for daily entries lists, ensuring Last-Write-Wins (LWW) resolution.
- [ ] **Milestone Logging:** Document all database schema updates, sync rules, and reward calculations in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) upon completion.

---

## 2. Subagent Beta (Frontend & Local Storage) Commands
- [ ] **Drift Table Generation:** Create Drift models inside `client/lib/database/` for:
  - `DailyWords`: Fields for id, Greek_word, English_translation, Greek_definition, English_definition, created_at, is_dirty.
  - `DailyTrivia`: Fields for id, fact_text, source_url, created_at, is_dirty.
  - Run database code generators to create matching DAOs and stream builders.
- [ ] **Vocabulary Dashboard UI:** Build the vocabulary logs viewer in `client/lib/presentation/widgets/` following the Everforest color scheme:
  - Scaffold screen canvas set to `EverforestColors.bg0`.
  - Words cards and trivia timelines set to `EverforestColors.bg1`.
  - 1px thin outlines set to `EverforestColors.bg2` around each component card.
  - Custom typography using `EverforestColors.fg` for headers and `grey` for definitions.
- [ ] **Trivia timeline widget:** Build vertical scroll timelines presenting daily facts summaries.
- [ ] **Change Documentation:** Update the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) with details of all new Drift tables, Words grids, and trivia logs created.

---

## 3. Subagent Gamma (Systems, Security & Network) Commands
- [ ] **Dictionary API Connector:** Write translation wrappers in Go (`backend/host-daemon/internal/infinity/`) consuming public dictionary API endpoints.
- [ ] **Markdown Notes Watcher:** Write parser scripts in Go scanning daily notes folders for new vocabulary entries.
- [ ] **REST API Endpoints:** Register server handlers in the daemon configuration:
  - `GET /api/v1/infinity/daily`: List current word collections.
  - `POST /api/v1/infinity/words`: Upload vocabulary terms.
  - `POST /api/v1/infinity/trivia`: Append daily facts.
- [ ] **Execution Log Update:** Record details of Go translators and Markdown scans in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) before final delivery.
