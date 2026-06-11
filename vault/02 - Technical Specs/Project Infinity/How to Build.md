# How to Build | Project Infinity

This document outlines the step-by-step coding directives and architectural wiring instructions for developer subagents to implement the Project Infinity daily vocabulary system.

---

## 1. Step-by-Step Implementation Flow

### Step 1: Go Daemon Translation & Scans (Subagent Gamma)
1. **Directory Allocation:** Create the package in `backend/host-daemon/internal/infinity/`.
2. **Dictionary client:** Implement Go routines to fetch translations:
   ```go
   func FetchTranslation(word string) (*Definition, error) {
       // Perform HTTP requests querying translation API services
       return queryDictionaryAPI(word)
   }
   ```
3. **Daily notes scanner:** Construct parser routines scanning daily folders.

### Step 2: SQLite Drift Schema Migration (Subagent Beta)
1. **Table Mappings:** Add `DailyWordsTable` and `DailyTriviaTable` class definitions in `client/lib/database/tables.dart`.
2. **SQLite Compilation:** Run code generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. **DAO Integration:** Define select queries delivering daily entries lists sorted by creation date.

### Step 3: Flutter Vocabulary Display UI (Subagent Beta)
1. **Everforest Colors:**
   - Scaffold canvas: `EverforestColors.bg0`.
   - Word cards: `EverforestColors.bg1`.
   - Outline separators: 1px border lines in `EverforestColors.bg2`.
   - Highlights: `EverforestColors.fg` (headers), `grey` (details).
2. **Study view layout:** Build card viewer widgets presenting time translation options.

### Step 4: Spaced Repetition Integration Hook (Subagent Alpha)
1. **Deck auto-generation:** Bind vocabulary changes to Flashcards modules:
   - Call `FlashcardSystem.createCard(word, definition)` upon database inserts.
2. **Sync Flags:** Set `is_dirty = 1` to command immediate synchronization loops.
