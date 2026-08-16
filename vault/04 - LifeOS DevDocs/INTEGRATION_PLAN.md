---
id: "8c2e5f14-9a7d-4b3e-8f61-2c9d4a1e5b70"
type: "lifeos_integration_plan"
last_modified: 1780100000000
sync_status: "clean"
---

> [!NOTE]
> **Home:** [[04 - LifeOS DevDocs/Home|Home]] | **Decided:** 2026-08-11 | **Status:** Plan COMPLETE 2026-08-11 — all 5 domains + attachment dedupe + photo embeds done

# Integration Plan: One API, Reference-Not-Copy

The roadmap for how tiles, the Zen Editor, and the backend connect. Everything below was agreed with the user on 2026-08-11.

---

## 1. The Two Decisions

1. **One API, routes per domain.** A single Go backend exposes `/api/v1/<domain>` route groups (movies, books, music, gallery, notes, pins...), all backed by one SQLite database. No per-app micro-APIs — one auth, one client, one deploy.
2. **External APIs live in the backend only.** TMDb, YouTube, etc. are called by the daemon, which holds the keys. The Flutter client never sees a third-party API key. Enriched metadata is stored in the DB and read by the client.

## 2. Core Principle: Reference, Don't Copy

The user's hard requirement: **no duplicate copies of the same thing.**

- Obsidian-style Ctrl-V creates a vault copy. LifeOS instead stores an asset **once** and references it everywhere.
- Every entity has a **natural key** for dedupe: movies → `imdb_id`/`tmdb_id`, books → `isbn`, music → track id, photos → `sha256` of content.
- The server dedupes on write: an attachment with an existing content hash returns the existing record instead of storing a second blob.
- Notes reference entities via links, not embedded copies: `movie:<id>`, `book:<isbn>`, `photo:<hash>`.

## 3. Data Flow

```
[Zen Editor note]──[[movie:tt0816692]]──┐
      │                                  │ render fetch (cached)
      v                                  v
[Local Drift DB = source of truth]  [GET /api/v1/movies/{id}]
      │ delta sync (backup + multi-device)
      v
[Go API :50051]  one DB, per-domain routes
      │
      ├── TMDb/YouTube/... (keys live here, results cached in DB)
      └── attachment store (dedupe by sha256)
```

Local-first: everything works offline against Drift. The server is backup + sync + remote access. A `cache_mode` setting (full | minimal) controls what the client keeps locally; offline renders use the local cache.

## 4. Open Endpoint Pattern (generic, per domain)

```
GET    /api/v1/<domain>?q=<search>&status=<filter>   # list + autocomplete (editor dropdown)
GET    /api/v1/<domain>/{id}                          # single entity (embed render)
POST   /api/v1/<domain>                               # create (sync write)
PUT    /api/v1/<domain>/{id}                          # update
DELETE /api/v1/<domain>/{id}                          # delete
POST   /api/v1/attachments                            # upload, dedupe by content hash
GET    /api/v1/attachments/{id}                       # blob fetch
```

`?q=` search is mandatory on every domain: it powers the Zen Editor autocomplete (`movie:` → dropdown → filter by status, e.g. `watched`).

## 5. Zen Editor Integration

- Typing `movie:` (or `/movie`) in the editor triggers autocomplete against `GET /api/v1/movies?q=...`.
- Selecting inserts a reference node `[[movie:<id>]]`.
- The node renders the entity's metadata inline as a card (poster, rating, status) — fetched from the API, cached locally.
- The same reference renders in the note and in the movies tile — one entity, two views.
- Media embeds open in the gallery view for editing; changes propagate back to the entity.

## 6. First Implementation: Movie Library

Already specced in [[02 - Technical Specs/Movie Library/What to Build|Movie Library Spec]]; add the search param to `GET /api/v1/movies?q=&status=`.

Order of work:
1. ~~`movies` route group on the daemon backed by SQLite (list + search, get, watchlist, reviews).~~ **DONE 2026-08-11** — `internal/movies`: `GET /api/v1/movies?q=&status=`, `GET /api/v1/movies/{id}` (includes avg rating), `GET|POST /api/v1/movies/watchlist` (dedupe by movie_id), `GET|POST /api/v1/movies/reviews` (upsert, one per movie, sets status WATCHED). `imdb_id` column added as dedupe key with migration. Test: `internal/movies/movies_test.go`.
2. ~~Client: movies tile reads from local Drift, syncs deltas; wire the editor autocomplete.~~ **DONE 2026-08-11** — `/movie` slash command opens a search dialog (`movie_embed_picker.dart`) querying `GET /api/v1/movies?q=&status=` with Watched/Available filter chips; picking a movie inserts a `zen_embed` node with `ref` = movie id. Embed preview renders the movie card from `GET /api/v1/movies/{id}` (`MoviesEmbedPreview(ref:)`). Round-trips to markdown as `![[movies|m3]]` (parser + bridge updated; digits stay height, anything else is a ref).
3. ~~TMDb enrichment in daemon (posters, ratings) cached in DB.~~ **DONE 2026-08-11** — `internal/movies/tmdb.go`: `TMDB_API_KEY` env var (no-op without it), find-by-imdb_id lookup, cached in movies.db (`tmdb_id`, `poster_path`, `overview`, `genres`, `tmdb_rating`, all guarded migrations). Background pass on startup + lazy enrich on `GET /api/v1/movies/{id}` + manual `POST /api/v1/movies/enrich`. Poster served as `poster_url` (image.tmdb.org, no key exposure to client), rendered in the embed card.
4. ~~Attachment dedupe (sha256) for gallery embeds.~~ **DONE 2026-08-11** — dedupe already existed end-to-end in `internal/gallery` (no new endpoints built): `POST /api/v1/gallery/upload` hashes content and returns `duplicate_of` (existing id), keeps the highest-resolution copy (replaces file + row when the new copy is better, skips the save otherwise); photos dedupe by **perceptual dHash** (identical photo, different compression → one copy), videos/undecodable files by content hash. `GET /api/v1/gallery/duplicates` groups by hash, client consumes it all via `CloudGalleryService` (`duplicateOf`). Gaps closed now: fallback content hash upgraded **md5 → sha256** (was the only non-sha256 hash left) and the dedupe flow got its first test (`internal/gallery/router_test.go`: same bytes uploaded twice → `duplicate_of` = first id, exactly one row stored). §4's generic `/api/v1/attachments` routes are already satisfied by `/api/v1/gallery/upload|stream|thumbnail` — same role, existing client.
5. ~~Repeat the pattern for books → music → notes → pins.~~ **ALL DONE 2026-08-11** — books, music, notes, pins below; photo ref embeds also done.

## 7. Next Steps

- **DONE 2026-08-11 (Drift ↔ daemon book sync):** daemon: `POST /api/v1/books` upserts a book pushed from the client (id+title required, status validated, `ON CONFLICT(id) DO UPDATE`, tested in `books_test.go`). Client: `epub_reader_screen.dart` now mirrors local writes to the daemon fire-and-forget — page turns → `POST /api/v1/books/progress` (updates daemon `current_page`), highlights → `POST /api/v1/books/highlight` (offline = silent no-op). The reverse direction (daemon→Drift) already existed via the dashboard's `_syncBooksFromBackend` pull (inserts missing books, never overwrites local progress). Book creation push is wired end-to-end ready (endpoint + test) — no UI creates books yet, so nothing to hook.

- **DONE 2026-08-11 (pins — plan complete):** daemon (`internal/location`, no DB — in-memory + `./data/geofences.json`): `?q=` filter (name) on `GET /api/v1/radar/geofences`, new `GET /api/v1/radar/geofences/{id}` (404 when missing, `geofences_test.go`). Client: `/pin` slash command + mobile File & Media (generic picker against `/api/v1/radar/geofences`); `MapsEmbedPreview(ref:)` renders `_SinglePinEmbed` (shared `_SingleEntityEmbed` card: type • coords, radius/polygon points, ACTIVE/INACTIVE badge).
- **DONE 2026-08-11 (photo ref embeds):** `![[photos|<asset id>]]` now renders a single gallery asset as a card with its thumbnail. Daemon: added `GET /api/v1/gallery/asset?id=` (single-asset metadata, same shape as `/assets`, 404 when missing, tested) and `?q=` filter on `GET /api/v1/gallery/assets` (title/filename/source) so the picker search works. Client: `PhotosEmbedPreview(ref:)` renders `_SinglePhotoEmbed` (thumbnail from `thumbnail?id=`, title/filename, source • dimensions, date, top tags); new `/photo` slash command + mobile File & Media (generic `EntityEmbedPickerDialog` against `/api/v1/gallery/assets`).

- **DONE 2026-08-11 (notes):** new `internal/notes` module (no DB — walks the vault). `GET /api/v1/notes?q=` lists `.md` files (title/path LIKE, skips dot-dirs like `.obsidian`); `GET /api/v1/notes/{path...}` (Go `{path...}` wildcard so refs can contain slashes, e.g. `![[notes|01 - Tiles/Home]]`) returns id/title/path/snippet (first non-heading line), with path-traversal guard + `notes_test.go`. Registered in main.go against `./vault` (same dir `HandleSync` writes to — daemon must run from repo root). Client: `/note` slash command + File & Media reuse the generic picker (`/api/v1/notes`); `NotesEmbedPreview(ref:)` renders via the shared `_SingleEntityEmbed` card with a snippet; new `notes` ZenEmbedSpec (full view = ZenEditor).
- **DONE 2026-08-11 (music):** daemon (`internal/music`): `GET /api/v1/music/tracks?q=` (title/artist/album LIKE), `GET /api/v1/music/tracks/{id}`, plus fixed a pre-existing bug — the stream handler queried `file_path` which the schema never had (added with guarded migration + seed paths, `music_test.go`). Client: `/music` slash command + mobile File & Media reuse the generic `EntityEmbedPickerDialog` (`/api/v1/music/tracks`); `![[music|t1]]` embeds render via `_SingleTrackEmbed` (shared `_SingleEntityEmbed` card). The music strip stays on the local engine/Drift (local-first, like books).
- **DONE 2026-08-11 (books):** daemon (`internal/books`): `GET /api/v1/books?q=` (title/author LIKE search), `GET /api/v1/books/{id}`, `PUT /api/v1/books/{id}` (status `NOT_STARTED|READING|FINISHED`, guarded migration adds `status` column, test `internal/books/books_test.go`). Client: `/book` slash command + mobile File & Media share the **generic** `EntityEmbedPickerDialog` (movie picker refactored into it — one implementation for both domains); `![[books|book-1]]` embeds render via `_SingleBookEmbed` (shared `_SingleEntityEmbed` card with the movie embed). The books tile and embed strip stay **Drift-backed** (local-first, shows the user's real books) — the daemon books.db is the server-side copy; Drift↔daemon book sync now wired both ways (see top of §7).
- **DONE 2026-08-11 (tile + write-path):** the movies tile now reads the canonical store (`MovieRepository` polls `GET /api/v1/movies`) instead of the never-seeded engine; tap a card → bottom sheet with status chips, rating slider + comment, watchlist button → pushes to `PUT /api/v1/movies/{id}`, `POST /api/v1/movies/reviews`, `POST /api/v1/movies/watchlist`. Embed strip uses the same repository. `PUT /api/v1/movies/{id}` added to the daemon (status validation + test).
- Set `TMDB_API_KEY` on the host running the daemon to activate enrichment.
- Attachment dedupe (sha256) for gallery embeds. **DONE — see step 4 above** (dedupe pre-existed in `internal/gallery`; md5→sha256 + dedupe test added 2026-08-11).
- Repeat the movies pattern for pins. **DONE — see step 5/7 above (2026-08-11).**
- Known divergence: the daemon keeps one `.db` file per module (movies.db, books.db...); unifying into one database is a separate refactor, tracked here until done.
