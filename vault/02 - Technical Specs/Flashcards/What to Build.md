# What to Build | Flashcards

This document specifies the exact SQLite schemas, REST API paths, and Flutter widget components to build for the Flashcards active recall system.

---

## 1. Database Architecture (SQLite / Drift)

Three tables must be defined in the SQLite cache layer to support Spaced Repetition (SRS) review loops, decks, and metrics.

```sql
-- Schema for Flashcard Decks
CREATE TABLE IF NOT EXISTS flashcard_decks (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0
);

-- Schema for Flashcards Items
CREATE TABLE IF NOT EXISTS flashcards (
    id TEXT PRIMARY KEY,
    deck_id TEXT NOT NULL,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    interval_days INTEGER DEFAULT 0,
    repetitions INTEGER DEFAULT 0,
    ease_factor REAL DEFAULT 2.5,
    next_review INTEGER NOT NULL, -- Unix timestamp
    created_at INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0,
    FOREIGN KEY(deck_id) REFERENCES flashcard_decks(id) ON DELETE CASCADE
);

-- Schema for Flashcard Review Logs
CREATE TABLE IF NOT EXISTS flashcard_reviews (
    id TEXT PRIMARY KEY,
    card_id TEXT NOT NULL,
    timestamp INTEGER NOT NULL,
    quality INTEGER NOT NULL, -- 0-5 user rating
    is_dirty INTEGER DEFAULT 0,
    FOREIGN KEY(card_id) REFERENCES flashcards(id) ON DELETE CASCADE
);
```

---

## 2. API Specifications (Go Backend Daemon)

The host daemon manages Anki zip decompression, scans local notes files for inline question keys, and registers sync controllers.

### REST Endpoints
- **List & Sync Decks:**
  - `GET /api/v1/flashcards/decks`
  - Response: `JSON` list of active decks, cards counts, and scheduled daily review targets.
- **Import Anki Package:**
  - `POST /api/v1/flashcards/import-anki`
  - Payload: File byte array stream (`.apkg`).
  - Response: Number of cards parsed and imported.
- **Scanner Watch Trigger:**
  - `POST /api/v1/flashcards/scan`
  - Response: Total cards parsed from inline notes.

---

## 3. UI Component Registry (Flutter Client)

All widgets are declared inside `client/lib/presentation/widgets/` or plugins:

- **`FlashcardsDashboard`:** Main screen displaying daily study targets, active decks list grid, and historical performance graphs.
- **`FlashcardSessionScreen`:** Active session player layout presenting clean text cards, tap gesture flips, and SM-2 quality response buttons.
- **`DeckCard`:** Compact folder block rendering deck properties, progress meters, and review schedules.
