# Database & Metadata Specifications

## 1. Local Caching Storage Engine (Drift/SQLite)

The Flutter clients utilize a strictly typed local database to provide offline support and rapid hydration.

### The `LifeEntities` Core Table
To unify metrics, habits, and tasks, the system uses a polymorphic base entity tracking schema:
*   `id`: UUID v4 (Primary Key)
*   `title`: String (Task description, habit name, etc.)
*   `description`: Nullable String
*   `created_at`: Epoch timestamp (integer)
*   `updated_at`: Epoch timestamp (integer)
*   `synced_at`: Nullable Epoch timestamp (null signifies the record is dirty and requires syncing)
*   `is_deleted`: Integer flag (0 = active, 1 = soft deleted)

## 2. Obsidian YAML Frontmatter Linkage
When local `LifeEntities` are synced to the host, they are materialized directly into the Vault as distinct Markdown files.

### Schema Rules
Each file **must** begin with a strict YAML frontmatter block containing identical schema state data:
```yaml
---
id: 550e8400-e29b-41d4-a716-446655440000
updated_at: 1718005000
synced_at: 1718005000
---
```
*   **Newline Rules:** Standard `\n` line endings must be enforced regardless of the host OS to prevent git/sync delta conflicts.
