# What to Do | Flashcards

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Flashcards|Flashcards]]



This document outlines the development tasks and subagent assignments for implementing the Flashcards system, utilizing active recall and spaced repetition spaced intervals.

---

## 1. Subagent Alpha (Lead Architect) Commands
- [ ] **DATA_SCHEMAS.md Integration:** Update the system database layout in `vault/04 - LifeOS DevDocs/DATA_SCHEMAS.md` to define relational schemas for the `flashcard_decks`, `flashcards`, and `flashcard_reviews` tables.
- [ ] **Point Star Reward Logic:** Define tracking rules for the Point Star System:
  - Add **+1 Star Point** to the user's ledger for every 10 reviewed flashcards.
  - Add **+2 Star Points** for completing a daily study streak review.
- [ ] **Conflict Resolution Specifications:** Define sync conflict schemas for card review timestamps, ensuring client-driven Last-Write-Wins (LWW) resolution.
- [ ] **Milestone Logging:** Document all database schema updates, sync rules, and reward calculations in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) upon completion.

---

## 2. Subagent Beta (Frontend & Local Storage) Commands
- [ ] **Drift Table Generation:** Create Drift models inside `client/lib/database/` for:
  - `FlashcardDecks`: Fields for id, name, created_at, is_dirty.
  - `Flashcards`: Fields for id, deck_id, question, answer, interval_days, repetitions, ease_factor, next_review, is_dirty.
  - `FlashcardReviews`: Fields for id, card_id, timestamp, quality, is_dirty.
  - Run database code generators to create matching DAOs and stream builders.
- [ ] **Decks Dashboard UI:** Build the main decks dashboard interface in `client/lib/presentation/widgets/` following the Everforest color scheme:
  - Scaffold screen canvas set to `EverforestColors.bg0`.
  - Deck cards and review slots set to `EverforestColors.bg1`.
  - 1px thin outlines set to `EverforestColors.bg2` around each component card.
  - Custom typography using `EverforestColors.fg` for headers and `grey` for status labels.
- [ ] **Interactive Flashcards View:** Build visual screen panels displaying card faces with touch gesture flips and minimalist pass/fail scoring control switches.
- [ ] **Change Documentation:** Update the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) with details of all new Drift tables, active review viewports, and SM-2 trackers created.

---

## 3. Subagent Gamma (Systems, Security & Network) Commands
- [ ] **Anki Package Importer:** Write an archive extraction utility in Go (`backend/host-daemon/internal/flashcards/`) parsing `.apkg` files, unzipping contents, and translating Anki SQL tables into the local SQLite schema.
- [ ] **Inline Flashcard Notes Parser:** Write markdown scanners in Go reading vault directories to auto-generate question/answer pairs separating at `::` characters.
- [ ] **REST API Sync Endpoints:** Register server handlers in the daemon configuration:
  - `GET /api/v1/flashcards/decks`: Retrieve study decks metadata list.
  - `POST /api/v1/flashcards/import`: Endpoint to load external Anki package files.
- [ ] **Execution Log Update:** Record details of Anki imports and Markdown scan watchers in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) before final delivery.
