---
id: "a1b2c3d4-0002-4a5b-9c0d-lifeosstate1"
type: "lifeos_state_management"
last_modified: 1784500000000
sync_status: "clean"
---

# LifeOS Client State Management

> [!NOTE]
> **Home:** [[04 - LifeOS DevDocs/Home|Home]] | **Related:** [[04 - LifeOS DevDocs/DATA_SCHEMAS|Data Schemas]] · [[04 - LifeOS DevDocs/SYNC_PROTOCOL|Sync Protocol]] · [[04 - LifeOS DevDocs/BACKEND_ARCHITECTURE|Backend Architecture]]

This document specifies how the Flutter client (`lifeos_client` v1.5.0+2) manages application state in August 2026. The client is **local-first**: the on-device Drift database is the source of truth, and every remote call is a synchronization event rather than a read dependency.

---

## 1. Architecture Overview

State is organized in four layers:

| Layer | Component | Responsibility |
|---|---|---|
| Persistence | Drift / SQLite (60 tables, WAL mode) | source of truth, reactive streams |
| Services | `ApiClient`, `PreferencesService`, `AuthService`, `EventHub` | I/O, auth, push events |
| Sync | `CustomSyncManager` + `SyncInterceptor` | dirty tracking, push/pull, LWW merge |
| UI | `SpatialEngineScaffold`, module widgets | spatial navigation, rendering |

Data flows one direction: mutations go to Drift → the sync layer marks rows dirty and flushes → inbound payloads are merged back into Drift → reactive streams notify UI.

---

## 2. Database Layer (Drift)

- **60 tables** across all modules, SQLite via Drift with **WAL mode** enabled.
- **20 DAOs** wrap table access with typed reactive queries.
- Every table carries the sync quartet: `id`, `updatedAt`, `syncedAt`, `isDirty` (see [[04 - LifeOS DevDocs/SYNC_PROTOCOL|Sync Protocol]]).
- UI subscribes to DAO streams (e.g. `watchAll()`) — no manual `setState` refresh loops; Drift emits change notifications on commit.

### Platform executers

| Platform | Executor | Notes |
|---|---|---|
| Android / Windows | native Drift (sqlite3) | direct file DB |
| Web | `db_executor_web` | `sqlite3.wasm` + `drift_worker.js` shared worker; persists via IndexedDB |

---

## 3. Service Layer

### 3.1 ApiClient (singleton)

- Plain `http`-based client, no codegen (no `dio`/`retrofit`).
- Timeouts: **2s** connect, **5s** request, **120s** long-request (large payloads/uploads).
- Buffered offline queue `_syncQueue`; every failed request is queued and **flushed every 15s** or on connectivity recovery.
- Base URL resolves per environment; token injected from `AuthService` for authorized calls.

### 3.2 PreferencesService

- JSON-backed reactive preferences (device-level settings not stored in Drift).
- Exposes `ValueNotifier`/streams so the UI re-renders on preference change without reload.

### 3.3 AuthService (singleton)

- Holds the JWT **in memory** for the session.
- **Remember-me** persists the token via `flutter_secure_storage`.
- Session restore on app start (`restoreSession()`); expired/invalid tokens trigger re-login.
- **Offline fallback**: when the daemon is unreachable, an ADMIN **"Local Mode"** session is created so the device remains fully usable; the flag is cleared once real auth succeeds.
- Web variant: `oauth_browser_web` reads the JWT from `localStorage('lifeos_token')` (written by the OAuth callback); `web_session_guard` watches for idle session expiry and signs out.

### 3.4 EventHub

- Reconnecting **WebSocket** to `/api/v1/events?token=<jwt>`.
- Server pushes domain facts as topics, e.g. `points:balance-change`.
- The hub dispatches typed events to registered listeners (points UI, HUD, module widgets) so state updates propagate without polling.

---

## 4. Synchronization State

### 4.1 CustomSyncManager

- Scans all 60 tables for `isDirty = 1` rows.
- Builds a batched payload: JSON → **gzip** → **base64**.
- Pushes to the relay (`POST /api/sync`, port 8080) or the daemon sync endpoint; on success clears dirty flags and applies the inbound payload.
- **LWW merge**: inbound rows are applied only when their `updatedAt` is newer than the local `updatedAt`, inside a single atomic SQLite transaction (see [[04 - LifeOS DevDocs/SYNC_PROTOCOL|Sync Protocol]]).
- Server-authoritative LWW for RPG tables (`player_stats`, `xp_ledger`, `atrophy_log`, `status_effects`): the backend validates XP/level math and pushes back absolute truth.

### 4.2 SyncInterceptor

- Wraps DAO writes; every insert/update automatically sets `updatedAt` (now) and `isDirty` (1), and clears `syncedAt` on local edits.
- Guarantees the quartet invariant on all 60 tables without per-module boilerplate.

### 4.3 Conflict handling

- Concurrent edits to the same row resolve by newest `updatedAt` (LWW); the loser is silently discarded (documented limitation).
- Zen/notes use tombstone-based LWW sync via the `zen` domain (`data/zen` DB-backed store); the web build has **no disk** — the zen store lives in the backend DB only.

---

## 5. Spatial UI State

- `SpatialEngineScaffold` owns navigation state: the home screen is a **2D matrix grid of modules**.
- Input model:
  - Arrow keys move a cursor through the grid (`[x,y]` coordinates shown in the HUD).
  - **Double-bump** at a grid edge navigates to the neighboring screen (pan).
  - **Escape** pops the navigation back-stack.
- Motion: 350ms `easeOutCubic` transitions between cells/screens.
- Rendering: heavy module frames are cached with `RepaintBoundary` so idle cells do not repaint during cursor movement.
- `PointStarSystem` subscribes to `points:balance-change` events and re-renders the HUD stars live (1 star = 100 points).

---

## 6. Representative Data Flow: Points Balance Change

1. User completes a task; the RPG domain applies reward logic (task +15 XP per automations rules).
2. DAO write commits to Drift (task row + `xp_ledger` row), `SyncInterceptor` marks rows dirty.
3. Drift streams notify the task UI and `PointStarSystem`.
4. `CustomSyncManager` flush (≤15s) pushes the gzip/base64 payload to the relay.
5. Daemon validates/derives server state and returns inbound payload; client merges under LWW.
6. EventHub receives `points:balance-change` and refreshes any live views (HUD stars, leaderboards).

---

## 7. Web-Specific Considerations

| Concern | Mechanism |
|---|---|
| DB engine | `db_executor_web` — `sqlite3.wasm` + `drift_worker.js` (IndexedDB) |
| Auth token | `localStorage('lifeos_token')` via `oauth_browser_web` |
| Idle security | `web_session_guard` idle watchdog signs out stale sessions |
| Zen storage | no local disk — backend DB is the only zen store; LWW + tombstones |
| Offline queue | `_syncQueue` buffer + 15s flush, same as native |

---

## Related Documents

- [[04 - LifeOS DevDocs/DATA_SCHEMAS|Data Schemas]]
- [[04 - LifeOS DevDocs/SYNC_PROTOCOL|Sync Protocol]]
- [[04 - LifeOS DevDocs/SECURITY_MODEL|Security Model]]
- [[04 - LifeOS DevDocs/UI_UX_GUIDELINES|UI/UX Guidelines]]