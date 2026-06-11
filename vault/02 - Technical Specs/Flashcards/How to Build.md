# How to Build | Flashcards

This document outlines the step-by-step coding directives and architectural wiring instructions for developer subagents to implement the Flashcards active recall system.

---

## 1. Step-by-Step Implementation Flow

### Step 1: Go Daemon Anki & Notes Parsing (Subagent Gamma)
1. **Directory Allocation:** Create the package files in `backend/host-daemon/internal/flashcards/`.
2. **Anki Importer:** Write Go routines to extract `.apkg` files (standard ZIP archive containing `collection.anki2` SQLite databases):
   ```go
   func ParseAnkiPackage(zipPath string) ([]Card, error) {
       // Unzip package and query collection.anki2 SQLite database
       db, err := sql.Open("sqlite3", tempAnkiDBPath)
       if err != nil {
           return nil, err
       }
       defer db.Close()
       // Query note fields and format translation
       return queryAnkiCards(db)
   }
   ```
3. **Markdown Tag Watcher:** Scan notes directory parsing text arrays matching `Question::Answer` string splits.

### Step 2: SQLite Drift Schema Migration (Subagent Beta)
1. **Table Mappings:** Add `FlashcardDecksTable`, `FlashcardsTable`, and `FlashcardReviewsTable` class definitions in `client/lib/database/tables.dart`.
2. **SQLite Compilation:** Run code generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. **DAO Integration:** Define database queries extracting review lists scheduled for dates prior to current time vectors.

### Step 3: Flutter Interactive Study Session UI (Subagent Beta)
1. **Everforest Colors:**
   - Scaffold backdrop: `EverforestColors.bg0`.
   - Card displays: `EverforestColors.bg1`.
   - Outlines: 1px borders in `EverforestColors.bg2`.
   - Accent triggers: `green` (complete), `grey` (details).
2. **Gesture Controller:** Implement double-tap coordinate listeners to rotate card graphics displaying answers.

### Step 4: Star Point Calculation Hook (Subagent Alpha)
1. **Transaction Triggers:** Register rewards inside local review operations:
   - Call `PointStarSystem.addPoints(1)` upon reviews of 10 card items.
   - Call `PointStarSystem.addPoints(2)` when completing a study session.
2. **Sync Vector:** Set `is_dirty = 1` to command immediate Tailscale synchronization sync loops.
