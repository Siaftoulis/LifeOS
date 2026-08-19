---
id: "a1b2c3d4-0005-4a5b-9c0d-lifeosbackend1"
type: "lifeos_backend_architecture"
last_modified: 1784500000000
sync_status: "clean"
---

# LifeOS Backend Architecture

> [!NOTE]
> **Home:** [[04 - LifeOS DevDocs/Home|Home]] | **Related:** [[04 - LifeOS DevDocs/SECURITY_MODEL|Security Model]] · [[04 - LifeOS DevDocs/PROXY_SETUP|Proxy Setup]] · [[04 - LifeOS DevDocs/INTEGRATION_PLAN|Integration Plan]] · [[04 - LifeOS DevDocs/DEPLOYMENT_CI_CD|Deployment & CI/CD]]

This document describes the Go backend as it exists in August 2026: a single host daemon serving the full `/api/v1/<domain>` surface over the tailnet, plus a standalone sync relay.

---

## 1. Components & Ports

| Component | Location | Listeners | Purpose |
|---|---|---|---|
| Host daemon | `backend/host-daemon/` | `:50051` tailnet HTTP, `:50052` Funnel upstream | all domain APIs + web portal |
| Sync relay | `server/` (repo root) | `:8080` | `POST /api/sync` → `generic_vault.jsonl`; `GET /ws` Yjs room relay |
| Web portal | served by daemon at `/` | — | `http.FileServer(http.Dir("./web"))`, no-cache headers, service worker purged |

- `:50051` is reachable only over the WireGuard tailnet (embedded `tsnet`, node `lifeos-host`).
- `:50052` is the Funnel upstream target (TCP 443 → `127.0.0.1:50052`), exposing only the web portal publicly.

---

## 2. Design Decisions (INTEGRATION_PLAN, 2026-08-11)

1. **One daemon, one API**: all domains are `/api/v1/<domain>` route groups on the single daemon; no per-domain microservices.
2. **External API keys live only in the backend** (env vars): `TMDB_API_KEY`, `GITHUB_OAUTH_CLIENT_ID/SECRET`, `GOOGLE_OAUTH_CLIENT_ID/SECRET`, DDNS, `LLM_BASE_URL`/`LLM_API_KEY` (default `http://localhost:11434/v1`, `llama3.2`).
3. **Reference-not-copy entities**: cross-domain references by external ID (`movie:imdb_id`, `book:isbn`, `photo:sha256`) instead of duplicating data.
4. **Local-first**: the backend is the sync/authority endpoint; clients hold the primary copy locally.
5. **Every domain endpoint supports `?q=` search**.

---

## 3. Auth & Middleware

- **Global JWT gate**: `internal/auth/middleware/jwt.go` — HS256, 24h expiry; `JWT_SECRET` env → `data/jwt_secret` file → random fallback.
- **Public allowlist**: login, register, oauth providers/start + callback, `/api/markdown/collab`, `/api/v1/events`, `/api/v1/radar/live`, `/api/v1/music/*`.
- **`publicOnly` handler** denies register/login on the Funnel path (invite-only registration).
- **Roles**: `ADMIN`, `USER` (NORMAL), `CHILD`; bcrypt password hashing; per-IP limiter (5 fails/5min); SQLite user store seeding admin `panospds`.
- **Child Lock**: CHILD-role interceptor in the `system` domain locks settings routes.
- **OAuth SSO**: `internal/oauth` — GitHub `read:user`, Google `openid email profile`; state-cookie CSRF (10 min); `data/oauth_users.json` mapping; web JWT → `localStorage('lifeos_token')`.
- **HMAC signing**: `crypto/hmac.go` with `HMAC_SECRET` signs infrastructure actions.

---

## 4. Domain Packages (`internal/`, ~38)

| Domain | Highlights |
|---|---|
| `auth` | login/register/JWT, roles, user store |
| `oauth` | GitHub/Google SSO, state cookie |
| `player` | RPG: XP, leveling sigmoid, quests (add/accept/complete/activate/cancel), XP decay/atrophy, illness apply/recover, task rewards |
| `points` | leaderboard, ledger, balance, store, vouchers/redeem, app-costs, apps/deduct (stars = points/100) |
| `movies` | TMDB enrichment; statuses AVAILABLE/DOWNLOADING/WATCHED; watchlist, reviews, subtitles tables |
| `music` | yt-dlp search/download → `data/media/music`; m4a proxy streaming (background cache, CORS/byte-range); LRCLIB lyrics; public route group |
| `books` | Gutenberg/OpenLibrary/MangaDex/Annas parallel search; download jobs; epub zip; audiobook mp3 stream; LLM describe/summarize/chat |
| `notes`, `media`, `gallery` | gallery: sha256/dHash dedupe, dominant colors, smart picker, `data/gallery/<user>/<year>/<month>` |
| `banking` | PDF parser, accounts/transactions |
| `accounting` | JSON-RPC stub |
| `home` | devices/toggle/sensors/report |
| `infinity` | daily words/trivia |
| `knowledge` | categories/articles |
| `flashcards` | decks, import-anki, scan |
| `zen` | DB-backed fs CRUD, LWW sync with tombstones (web has no disk) |
| `engine` | 26 entity types; `engine:upsert:<type>` events; notifications |
| `system` | settings; Child Lock interceptor; apps classifier |
| `backup` | list/upload/download/chunk/merge |
| `vm` | list/toggle/discovery/explore |
| `youtube` | NewPipe bridge jar `127.0.0.1:18785`; sessions cost −10 pts/30min |
| `voice-parse`, `markdown` | markdown: collab WS hubs per-doc, vault sync |
| `location` | geofences/report/routing; radar WS |
| `events` | WS broker of bus facts; token-auth |
| `bus` | in-memory pub/sub: patterns `domain:*`, `*:action`, `*:*` |
| `telemetry` | XOR-obfuscated (`'lifeos-tel-2026-x'`), server-side rules/dedup/cap |
| `automations` | `location:enter` → webhook; `points:negative-balance` → `tv_lock`; engine rules: task +15, habit +10, zen log +20 |
| `sync` | push base64+gzip; LWW by ms timestamps; APK update download; vault watcher |
| `darkweb` | torrents/promote |
| `sandbox` | cloud upload + clamdscan |
| `cloud` | backups/web-os stubs |
| `kb` | topics/export-flashcards/search stubs |
| `chtm` | stats |
| `devsim` | multipart reports → `vault/03 - work/dev_simulations` |
| `illness`, `calendar` | illness; calendar via `data/calendar.json` |

> [!NOTE]
> Relay-side ACL: `server/` enforces per-room permissions from `lifeos.db` on `/ws`; when the permissions table is empty, all rooms are allowed (bootstrap default).

---

## 5. Storage

- **One SQLite `.db` per module** in `data/` — one per domain: gallery, movies, books, finance, rpg, knowledge, flashcards, media, home, infinity, backup, darkweb, vm, voice, youtube, system, sync, engine, sandbox, devsim, zen, plus relay DB `lifeos-relay` / `lifeos.db`.
- **JSON stores**: `calendar.json`, `geofences.json`, `points.json`, `ledger.json`, `illness.json`.
- `data/` is gitignored — users, keys, and runtime state never enter the repository.

---

## 6. Relay (`server/`)

| Route | Behavior |
|---|---|
| `POST /api/sync` | append payload to `generic_vault.jsonl` |
| `GET /ws` | Yjs room relay; per-room ACL from `lifeos.db` permissions (allow-all when empty) |

---

## 7. Code Organization Conventions

- Domain-driven directory structure under `internal/`; each domain splits models, store (data access), and routing into separate files.
- Stateless handlers: requests map directly to store operations.
- Public web assets served from `./web` with no-cache headers; service worker removed at deploy time (see [[04 - LifeOS DevDocs/DEPLOYMENT_CI_CD|Deployment & CI/CD]]).

---

## Related Documents

- [[04 - LifeOS DevDocs/SECURITY_MODEL|Security Model]]
- [[04 - LifeOS DevDocs/INTEGRATION_PLAN|Integration Plan]]
- [[04 - LifeOS DevDocs/SYNC_PROTOCOL|Sync Protocol]]
- [[04 - LifeOS DevDocs/PROXY_SETUP|Proxy Setup]]
- [[04 - LifeOS DevDocs/Home|Home]]