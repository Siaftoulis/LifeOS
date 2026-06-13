# What to Build | Knowledge Base

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Knowledge Base|Knowledge Base]]



This document specifies the exact SQLite schemas, REST API paths, and Flutter widget components to build for the Knowledge Base cataloging dashboard.

---

## 1. Database Architecture (SQLite / Drift)

Two tables must be defined in the SQLite cache layer to support topics categorization, markdown paths, and links relationships.

```sql
-- Schema for Knowledge Topics
CREATE TABLE IF NOT EXISTS knowledge_topics (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    category TEXT NOT NULL, -- 'TECH', 'SCIENCE', 'PHILOSOPHY', 'HISTORY'
    status TEXT NOT NULL, -- 'LEARNING', 'COMPLETED', 'BACKLOG'
    note_path TEXT NOT NULL UNIQUE,
    last_studied INTEGER NOT NULL, -- Unix timestamp
    is_dirty INTEGER DEFAULT 0
);

-- Schema for Topics Relationships
CREATE TABLE IF NOT EXISTS knowledge_relationships (
    id TEXT PRIMARY KEY,
    source_id TEXT NOT NULL,
    target_id TEXT NOT NULL,
    relation_type TEXT NOT NULL, -- 'REQUIRES', 'EXPANDS', 'CONTRADICTS'
    is_dirty INTEGER DEFAULT 0,
    FOREIGN KEY(source_id) REFERENCES knowledge_topics(id) ON DELETE CASCADE,
    FOREIGN KEY(target_id) REFERENCES knowledge_topics(id) ON DELETE CASCADE
);
```

---

## 2. API Specifications (Go Backend Daemon)

The host daemon indexes vault note tags, maintains relative path variables, and returns search records.

### REST Endpoints
- **List & Control Topics:**
  - `GET /api/v1/kb/topics`
  - Response: `JSON` list of categorized topics, study statuses, and paths.
- **Search Metadata Index:**
  - `GET /api/v1/kb/search?query=automation`
  - Response: List of matching documents, tags, and header anchors.
- **Flashcard Export Webhook:**
  - `POST /api/v1/kb/export-flashcards`
  - Payload: `{"topic_id": "math_calculus"}`
  - Response: Success confirmation status.

---

## 3. UI Component Registry (Flutter Client)

All widgets are declared inside `client/lib/presentation/widgets/` or plugins:

- **`KnowledgeBaseDashboard`:** Main screen presenting directories, dynamic note stats, and study status meters.
- **`TopicCardWidget`:** Folders view widget summarizing category detail lists, tags badges, and action triggers.
- **`RelationshipGraphWidget`:** Localized vector graph panel drawing connections between topics in active review modes.
