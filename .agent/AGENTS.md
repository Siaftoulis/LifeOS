# Project-Scoped Rules

## Continuous Feedback Loop (Multiple Choice)
- Whenever a feature or piece of architecture is built, automatically send back questions with multiple-choice options (e.g., Option 1, Option 2, Option 3).
- Use the `ask_question` tool with `is_multi_select: false` (or true if appropriate) to provide these options so the user can easily select the best path forward or write their own response.
- This ensures constant alignment and gives the user directional control after every major step.

## Architecture Rules (decided 2026-08-11, source: vault/04 - LifeOS DevDocs/INTEGRATION_PLAN.md)
- **One API, routes per domain.** All backend work goes on the single Go daemon as `/api/v1/<domain>` route groups (movies, books, music, gallery, notes, pins...), backed by one SQLite DB. NEVER create per-app micro-APIs or separate databases.
- **External API keys live in the backend only.** TMDb, YouTube, etc. are called by the daemon; the Flutter client never holds or calls third-party API keys.
- **Reference, don't copy.** Entities are stored once and referenced (movie:imdb_id, book:isbn, photo:sha256). No duplicate copies in the vault, client, or server. Attachments dedupe by content hash on upload.
- **Local-first.** Drift local DB is the source of truth; the server is backup + sync + remote access. Offline must always work.
- **Every domain endpoint includes `?q=` search** — it powers the Zen Editor autocomplete (`movie:` dropdown with filters like `watched`).
- When building a new tile, follow the generic endpoint pattern in INTEGRATION_PLAN.md §4 and link entities in the editor per §5.
- The `server/` sync relay (:8080) is separate from the daemon (:50051): domain REST lives on the daemon; the relay handles `/api/sync` + `/ws` only.
