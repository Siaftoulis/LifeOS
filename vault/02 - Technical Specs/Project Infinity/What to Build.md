# What to Build | Project Infinity

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Project Infinity|Project Infinity]]



This document specifies the exact SQLite schemas, REST API paths, and Flutter widget components to build for the Project Infinity daily vocabulary system.

---

## 1. Database Architecture (SQLite / Drift)

Two tables must be defined in the SQLite cache layer to support daily dictionary indexes, translations, and facts logging.

```sql
-- Schema for Daily Vocabulary Words
CREATE TABLE IF NOT EXISTS daily_words (
    id TEXT PRIMARY KEY,
    greek_word TEXT NOT NULL,
    english_translation TEXT NOT NULL,
    greek_definition TEXT,
    english_definition TEXT,
    created_at INTEGER NOT NULL, -- Unix timestamp
    updated_at INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0
);

-- Schema for Daily Trivia Facts
CREATE TABLE IF NOT EXISTS daily_trivia (
    id TEXT PRIMARY KEY,
    fact_text TEXT NOT NULL,
    source_url TEXT,
    created_at INTEGER NOT NULL, -- Unix timestamp
    is_dirty INTEGER DEFAULT 0
);
```

---

## 2. API Specifications (Go Backend Daemon)

The host daemon fetches translations from online dictionaries, scans daily study folders, and syncs flashcard records.

### REST Endpoints
- **List Daily Vocab:**
  - `GET /api/v1/infinity/daily`
  - Response: `JSON` list of daily vocabulary terms and trivia.
- **Add Daily Word:**
  - `POST /api/v1/infinity/words`
  - Payload: `{"word": "greek_word", "translation": "english"}`
  - Response: Dictionary definitions.
- **Log Daily Fact:**
  - `POST /api/v1/infinity/trivia`
  - Payload: `{"fact_text": "text_body"}`
  - Response: Success confirmation.

---

## 3. UI Component Registry (Flutter Client)

All widgets are declared inside `client/lib/presentation/widgets/` or plugins:

- **`ProjectInfinityDashboard`:** Main screen presenting Word of the Day cards, translation inputs, and study statistics.
- **`WordOfTheDayCard`:** Visual block presenting dictionary definitions and translation toggles.
- **`TriviaLogTimeline`:** Scrolling vertical timeline showing trivia entries.
