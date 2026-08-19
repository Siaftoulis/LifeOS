---
id: "a1b2c3d4-0006-4a5b-9c0d-lifeoscodebase1"
type: "lifeos_codebase_analysis"
last_modified: 1784500000000
sync_status: "clean"
---

# LifeOS Codebase Analysis & Architecture Report

This document contains a comprehensive analysis of the LifeOS codebase across the client, backend, and documentation vault. Updated August 2026 (previous snapshot: June 2026).

---

## 1. Overall Vision & Philosophy

LifeOS is a **local-first, offline-first, multi-platform personal operating system** consolidating a user's entire digital life into a single private workspace.

- **Digital Sovereignty**: data lives on your devices; nothing leaves the tailnet unless explicitly allowed (Funnel web portal).
- **Offline-First**: functions without internet; synchronizes opportunistically via buffered queues.
- **Gamification**: the Point Star System rewards productive actions and penalizes excessive leisure (task +15, habit +10, zen log +20 per engine automations rules).
- **Self-Hosted Infrastructure**: Tailscale mesh (embedded `tsnet`, node `lifeos-host`) with no cloud dependencies.
- **Design**: strict Everforest minimalist flat-line theme ([[04 - LifeOS DevDocs/UI_UX_GUIDELINES|UI/UX Guidelines]]).

---

## 2. Client Architecture (Flutter)

Client: `client/`, **v1.5.0+2** (Android, Windows, Web).

### App Initialization (`main.dart`)
1. Initialize `PreferencesService` (JSON reactive) and `AppDatabase` (Drift/SQLite).
2. Restore auth via `AuthService.restoreSession()` (JWT in memory, `flutter_secure_storage` remember-me; offline fallback = ADMIN "Local Mode" session).
3. Show login or `AppShell` (spatial grid dashboard).
4. Start `EventHub` WebSocket (`/api/v1/events?token=`) and location streaming.

### Local Database (Drift — 60 tables, WAL)
- **20 DAOs** with reactive streams; every table carries the sync quartet (`id`, `updatedAt`, `syncedAt`, `isDirty`).
- `SyncInterceptor` auto-marks dirty; `CustomSyncManager` flushes gzip+base64 payloads (15s poll / on connectivity).
- Web build uses `db_executor_web` (`sqlite3.wasm` + `drift_worker.js`, IndexedDB); `oauth_browser_web` reads `localStorage('lifeos_token')`; `web_session_guard` idle watchdog signs out.

### UI & Widgets
- **Spatial engine**: `SpatialEngineScaffold` 2D grid of modules; arrow-key nav, double-bump edge pan, Escape back-stack, 350ms `easeOutCubic`, `RepaintBoundary` caching; HUD `[x,y]` coordinates.
- **PointStarSystem**: family leaderboard, ledger, voucher redemption, point-gated module wrappers (stars = points/100), live updates via `points:balance-change` events.
- **Signature UIs**: Poweramp v3-style music player, Aves 1:1 gallery replica, AppFlowy-based zen editor (bold + gold highlight styling).
- **Android launcher**: flat grid/folder views, point-gated app launching.

---

## 3. Backend Infrastructure (Go)

### Components

| Component | Location | Ports |
|---|---|---|
| Host daemon | `backend/host-daemon/` | `:50051` tailnet HTTP, `:50052` Funnel upstream |
| Sync relay | `server/` | `:8080` (`POST /api/sync` → `generic_vault.jsonl`; `GET /ws` Yjs relay, per-room ACL from `lifeos.db`, allow-all when empty) |
| Web portal | served by daemon at `/` | `http.FileServer(http.Dir("./web"))`, no-cache, SW purged |

### Auth (August 2026)
- Global **JWT gate** (`internal/auth/middleware/jwt.go`): HS256, 24h expiry, `JWT_SECRET` env → `data/jwt_secret` → random fallback.
- Public allowlist: login, register, oauth start/callback, `/api/markdown/collab`, `/api/v1/events`, `/api/v1/radar/live`, `/api/v1/music/*`.
- `publicOnly` denies register/login on the Funnel path (invite-only). Roles ADMIN/USER/CHILD; bcrypt; per-IP limiter (5 fails/5min); seeded admin `panospds`.
- OAuth SSO (`internal/oauth`): GitHub `read:user`, Google `openid email profile`; state-cookie CSRF (10 min); `data/oauth_users.json`; web JWT → localStorage.

### Domain Modules (~38 `internal/` packages)
auth, oauth, player (RPG XP/leveling sigmoid/quests/decay/illness), points (leaderboard/ledger/store/vouchers/app-costs), movies (TMDB, AVAILABLE/DOWNLOADING/WATCHED), music (yt-dlp, m4a proxy, LRCLIB), books (Gutenberg/OpenLibrary/MangaDex/Annas, epub/audiobook, LLM describe/summarize/chat), notes, media, gallery (sha256/dHash dedupe, smart picker), banking (PDF parser), accounting (JSON-RPC stub), home (devices), infinity (daily words/trivia), knowledge, flashcards (import-anki), zen (DB-backed fs CRUD, tombstones), engine (26 entity types, `engine:upsert:<type>`), system (Child Lock, apps classifier), backup (chunk/merge), vm, youtube (NewPipe jar 127.0.0.1:18785, −10 pts/30min), voice-parse, markdown (collab WS hubs), location (geofences, radar WS), events (WS broker, token-auth), bus (in-memory pub/sub), telemetry (XOR `'lifeos-tel-2026-x'`, server cap), automations (`location:enter` → webhook, `points:negative-balance` → `tv_lock`), sync (base64+gzip LWW, APK update), darkweb, sandbox (clamdscan), cloud/kb (stubs), chtm (stats), devsim (reports to vault), illness, calendar.

### Storage
- One SQLite `.db` per module in `data/` (gallery, movies, books, finance, rpg, knowledge, flashcards, media, home, infinity, backup, darkweb, vm, voice, youtube, system, sync, engine, sandbox, devsim, zen, relay) + JSON stores (`calendar.json`, `geofences.json`, `points.json`, `ledger.json`, `illness.json`).
- Integration design (2026-08-11, [[04 - LifeOS DevDocs/INTEGRATION_PLAN|INTEGRATION_PLAN]]): single `/api/v1/<domain>` API; external keys backend-env-only; reference-not-copy entities (`movie:imdb_id`, `book:isbn`, `photo:sha256`); `?q=` search on every domain endpoint.

---

## 4. Synchronization Protocol

1. Local mutations set `isDirty` via `SyncInterceptor`; the 15s poller batches dirty rows.
2. Payload = `Base64(Gzip(JSON))`; pushed to the relay `POST /api/sync`.
3. Merge: entity-level **LWW by millisecond timestamps** inside a single atomic SQLite transaction.
4. RPG tables (`player_stats`, `xp_ledger`, `atrophy_log`, `status_effects`) use **server-authoritative LWW**.
5. Markdown: direct overwrite via daemon; **Yjs collaboration websockets** (`/api/markdown/collab`) added for live multi-user editing; Zen uses tombstone LWW.
6. APK updates are distributed through the `sync` domain (download endpoint).

---

## 5. Deployment & CI/CD

- **GitHub Actions** (`.github/workflows/release.yml`), triggered by `v*` tags:
  - `build-android`: ubuntu + Java 17; scaffold (`flutter create --project-name lifeos_client --org com.lifeos.app --platforms=android,windows`), restore `AndroidManifest.xml` with `LifeOSWidgetProvider`, strip `gradle.properties` Java lines, `flutter build apk --release`.
  - `build-windows`: same scaffold, `flutter build windows --release`, zip.
  - `publish-release`: `release_notes.md` from `.agent/version.json` (`build_number` currently 33); `softprops/action-gh-release` attaches APK + ZIP.
- **`deploy_server.ps1`**: `flutter build web` → strip `flutter_service_worker.js`, patch bootstrap cache-buster → cross-compile linux daemon+server (`CGO_ENABLED=0`) → `tailscale ssh root@pds-laptop-old` → systemd `lifeos-host-daemon` restart, MD5 verified.
- **`client/deploy.ps1`**: web-only deploys.
- Versioning: client `1.5.0+2`; latest tagged release `v1.4.0`; public portal `https://lifeos-host.husky-forel.ts.net`.

---

## 6. Point Star System Mechanics

- **Earning (automations/engine rules)**: tasks +15, habits +10, zen log +20; RPG rewards and leveling sigmoid in `player`.
- **Spending**: vouchers (redeem), app-costs, `apps/deduct`; YouTube sessions −10 pts/30min.
- **Units**: stars = points/100.
- **Penalties**: XP decay/atrophy; `points:negative-balance` → `tv_lock` webhook automation.
- **Gating**: external Android apps require points; CHILD role settings locked (Child Lock interceptor).

---

## 7. Current Project Status (August 2026)

**Active / Functional:**
- Spatial UI engine + 22+ registered modules; web portal on Funnel.
- Drift 60-table local-first stack with 20 DAOs and LWW sync.
- Host daemon with ~38 domains; JWT + OAuth + Child Lock; sync relay with Yjs rooms and ACL.
- CI/CD: Android APK + Windows ZIP releases; MD5-verified server deploys.
- RPG/points/automations loop (task/habit/zen rewards, TV lock, webhooks).

**Pending / Future Sprints:**
- `kb`/`cloud` domains are stubs (topics, backups, web-os).
- Relay room ACL defaults to allow-all until permissions are populated.
- Telemetry obfuscation is XOR-only (not encryption).
- CRDT convergence beyond LWW for relational tables remains a long-term target.

---

## Related Documents

- [[04 - LifeOS DevDocs/BACKEND_ARCHITECTURE|Backend Architecture]]
- [[04 - LifeOS DevDocs/STATE_MANAGEMENT|State Management]]
- [[04 - LifeOS DevDocs/SYNC_PROTOCOL|Sync Protocol]]
- [[04 - LifeOS DevDocs/SECURITY_MODEL|Security Model]]
- [[04 - LifeOS DevDocs/DEPLOYMENT_CI_CD|Deployment & CI/CD]]
- [[04 - LifeOS DevDocs/Home|Home]]