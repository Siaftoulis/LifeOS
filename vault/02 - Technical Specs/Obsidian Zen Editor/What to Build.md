# What to Build | Obsidian Zen Editor

This document specifies the exact SQLite schemas, REST API paths, and Flutter widget components to build for the Obsidian Zen Editor.

---

## 1. Database Architecture (SQLite / Drift)

Two tables must be defined in the SQLite cache layer to support note file catalogs, frontmatter summaries, and inter-file dependency linkages.

```sql
-- Schema for Markdown Notes Inventory
CREATE TABLE IF NOT EXISTS markdown_notes (
    id TEXT PRIMARY KEY,
    file_path TEXT NOT NULL UNIQUE,
    frontmatter_json TEXT, -- JSON map of metadata tags
    last_modified INTEGER NOT NULL,
    hash TEXT NOT NULL,
    is_dirty INTEGER DEFAULT 0
);

-- Schema for Notes Graph Index
CREATE TABLE IF NOT EXISTS notes_index (
    id TEXT PRIMARY KEY,
    word_count INTEGER DEFAULT 0,
    references_list TEXT, -- COMMA separated links IDs
    is_dirty INTEGER DEFAULT 0,
    FOREIGN KEY(id) REFERENCES markdown_notes(id) ON DELETE CASCADE
);
```

---

## 2. API Specifications (Go Backend Daemon)

The host daemon manages folder system checks, provides WebSocket collaborative channels, and parses YAML structures.

### REST Endpoints
- **Sync Note Document:**
  - `POST /api/markdown/sync`
  - Payload: `{"file_path": "path.md", "content": "text_body"}`
  - Response: Updated document hashes.
- **WebSocket Collab Endpoint:**
  - `WS /api/markdown/collab?doc_id={id}`
  - Format: Operational Transformation (OT) delta frames streaming text changes.
- **Obsidian Bridge Handshake:**
  - `GET /api/markdown/bridge`
  - Response: Server variables and sync status reports.

---

## 3. UI Component Registry (Flutter Client)

All widgets are declared inside `client/lib/presentation/widgets/` or plugins:

- **`ZenEditorWidget`:** Main interface presenting folder navigation, file list cards, and sync status checks.
- **`MarkdownFocusViewport`:** Writing area applying custom styling, focus fading effects, and auto-save timers.
- **`NotesGraphCanvas`:** Interactive graph canvas displaying links between notes.
