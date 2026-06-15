# Synchronization Protocols Specifications

> [!NOTE]
> **Home:** [[04 - LifeOS DevDocs/Home|Home]] | **Related:** [[04 - LifeOS DevDocs/SYNC_PROTOCOL|Sync Protocol Spec]] · [[04 - LifeOS DevDocs/Architecture/Custom_Sync_Engine|Custom Sync Engine]] · [[04 - LifeOS DevDocs/DATA_SCHEMAS|Data Schemas]] · [[04 - LifeOS DevDocs/EMBEDDED_NETWORK|Embedded Network]]


## 1. Local Caching & Dirty Tracking
Relational updates are captured on the entity level inside SQLite. Drift-managed tables implement synchronization columns directly, whereas custom SQL tables (such as `habits`) implement basic dirty-flag tracking columns:

```sql
CREATE TABLE habits (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    streak INTEGER DEFAULT 0,
    done INTEGER DEFAULT 0,
    is_dirty INTEGER DEFAULT 0
);
```

## 2. Sync Relay & Payload Processing
Every 15 seconds, the synchronization cycle extracts dirty rows and posts them to the Go Sync Server.
*   **Compression Routing:** Packs delta entities, encodes to JSON, compresses via GZIP, and encodes to Base64 before firing the payload upstream to `POST /api/sync/push`.
*   **Inbound Integration:** Incoming update envelopes are integrated on the client using SQLite `INSERT OR REPLACE` transactions checking that local modification timestamps are not overwritten by stale sync updates.

## 3. Markdown Document Synchronization
Markdown files (`.md`) are synced as complete files:
*   Note modifications are saved as raw strings locally via `MarkdownStorage`.
*   Files are synced upstream by posting the complete content payload (`Filename` and `Content`) to `POST /api/markdown/sync` exposed on the Go Host Daemon (port `50051`).
*   The Host Daemon overwrites the destination file inside the local Obsidian directory.
