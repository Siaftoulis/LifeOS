# What to Do | Knowledge Base

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Knowledge Base|Knowledge Base]]



This document outlines the development tasks and subagent assignments for implementing the Knowledge Base system, providing structured academic cataloging, tags hierarchy, and links indexing.

---

## 1. Subagent Alpha (Lead Architect) Commands
- [ ] **DATA_SCHEMAS.md Integration:** Update the system database layout in `vault/04 - LifeOS DevDocs/DATA_SCHEMAS.md` to define relational schemas for the `knowledge_topics` and `knowledge_relationships` tables.
- [ ] **Point Star Reward Logic:** Define tracking rules for the Point Star System:
  - Add **+5 Star Points** to the user's ledger for completing structural notes records.
- [ ] **Conflict Resolution Specifications:** Define sync conflict schemas for note tags lists, ensuring client-driven Last-Write-Wins (LWW) resolution.
- [ ] **Milestone Logging:** Document all database schema updates, sync rules, and reward calculations in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) upon completion.

---

## 2. Subagent Beta (Frontend & Local Storage) Commands
- [ ] **Drift Table Generation:** Create Drift models inside `client/lib/database/` for:
  - `KnowledgeTopics`: Fields for id, title, category, status, note_path, last_studied, is_dirty.
  - `KnowledgeRelationships`: Fields for id, source_id, target_id, relation_type, is_dirty.
  - Run database code generators to create matching DAOs and stream builders.
- [ ] **Knowledge Dashboard UI:** Build the topics directory grid in `client/lib/presentation/widgets/` following the Everforest color scheme:
  - Scaffold screen canvas set to `EverforestColors.bg0`.
  - Topic index folders and link boards set to `EverforestColors.bg1`.
  - 1px thin outlines set to `EverforestColors.bg2` around each component card.
  - Custom typography using `EverforestColors.fg` for headers and `grey` for categories details.
- [ ] **Study Status Grid:** Build toggles enabling user targets to be flagged for Flashcards deck creation on demand.
- [ ] **Change Documentation:** Update the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) with details of all new Drift tables, folders index grids, and relational connection views.

---

## 3. Subagent Gamma (Systems, Security & Network) Commands
- [ ] **Markdown Tags Parser:** Write directory watchers in Go (`backend/host-daemon/internal/kb/`) parsing markdown files to extract frontmatter tags.
- [ ] **Relational Graph Mapper:** Write scanning engines to detect links inside files, compiling records of linked topic categories.
- [ ] **REST API Sync Endpoints:** Register server handlers in the daemon configuration:
  - `GET /api/v1/kb/topics`: Retrieve logged academic records.
  - `POST /api/v1/kb/topics/study`: Toggle card generation triggers.
  - `GET /api/v1/kb/search`: Fast text search queries mapping search words.
- [ ] **Execution Log Update:** Record details of Go tags parser, database search filters, and graph links index in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) before final delivery.
