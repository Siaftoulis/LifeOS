---
last_modified: 1784500000000
---

# System Architecture Specification

This document details the multi-platform system architecture, modular components, and core data flow paths for the local-first, cross-compatible LifeOS application.

---

## 1. Monorepo Structural Blueprint

The LifeOS application is laid out as a monorepo workspace to manage both client runtimes and backend container layers in isolation.

```
lifeos-monorepo/
├── .agent/                      # Autonomous agent runtime environment data
│   ├── current_sprint.json      # Dynamic, decomposed task manifests
│   └── system_architecture.md   # System design and data flow configurations
├── backend/                     # Containerized self-hosted infrastructure
│   ├── Dockerfile.sync          # Minimal sync service deployment blueprint
│   └── docker-compose.yml       # Infrastructure layout stack (Database, Proxy)
├── client/                      # Flutter multi-platform core engine
│   ├── android/                 # Android native runner configurations & AAR bindings
│   ├── windows/                 # Windows native C++ runner & Cgo DLL bindings
│   └── lib/                     # Spatial UI Matrix, FeatureRegistry Plugins, and application state
└── vault/                       # Obsidian Vault (Markdown Assets & System Truth)
    └── 04 - LifeOS DevDocs/     # Specifications (System Source of Truth)
        ├── DATA_SCHEMAS.md      # Database tables, caching, and frontmatter patterns
        ├── EMBEDDED_NETWORK.md  # tsnet lifecycle and authentication logic
        └── SYNC_PROTOCOL.md     # Transactional field-level delta sync engine
```

---

## 2. Platform Target System Integration

The application compiles into native code targets, binding underlying OS capabilities directly. See [[04 - LifeOS DevDocs/Architecture/System_Design|System Design]] for the full architectural blueprint and [[04 - LifeOS DevDocs/DEPLOYMENT_CI_CD|Deployment & CI/CD]] for build pipeline details.

```
                  +-----------------------------------+
                  |        Flutter Core Engine        |
                  +-----------------------------------+
                                    |
                    +---------------+---------------+
                    |                               |
                    v                               v
       +-------------------------+     +-------------------------+
       |   Native Windows (x86)  |     |   Native Android (ARM)  |
       +-------------------------+     +-------------------------+
       | - C++ Runner compiled   |     | - Kotlin Host compiled  |
       |   via MSVC compiler.    |     |   via Gradle / NDK.     |
       | - Asynchronous Win32    |     | - inotify kernel events |
       |   ReadDirectoryChangesW |     |   listener for local    |
       |   for Obsidian Vault.   |     |   Obsidian folders.     |
       | - Go embedded via Cgo   |     | - Go Mobile .aar bindings|
       |   compiled C-Archive DLL|     |   for user-space tsnet. |
       +-------------------------+     +-------------------------+
```

---

## 3. Data Flow & Integration Lifecycle

The synchronization process bridges three major architectural nodes: the **Obsidian Vault Directory**, the **Local SQLite Database Cache (Drift)**, and the **Host Daemon** with its per-module SQLite stores. The system is local-first: the daemon and each client device hold authoritative relational state, exchanged through client-to-daemon polling and an events WebSocket bus.

Relevant tile modules: [[Maps & Live Tracking]] (telemetry), [[Calendar Habit Task Manager]] (data sync), [[Virtual Machine Management]] (Hyper-V), [[Obsidian Zen Editor]] (markdown vault), [[Home Management]] (smart home), [[Preferences Setting Tab]] (global config).

### Local-First Topology
The system enforces a localized split-plane topology:
1. **Local Go Daemon (Sidecar):** Runs as a background service on the desktop host to directly execute local OS shell routines (Hyper-V control, WOL), serve the REST `/api/v1/<domain>` surface behind a JWT gate, and persist per-module SQLite databases under `data/`.
2. **Client Drift Cache:** The Flutter client keeps a local-first SQLite cache (~60 tables) as the source of truth on each device. Synchronization is client-to-daemon polling with **base64 + gzip** payload push over the events WebSocket bus. There is no remote PostgreSQL or Docker relay stack in the trust path.

> [!NOTE]
> The originally planned "Remote Docker Stack (Relay & PostgreSQL) as central source of truth" never materialized. The daemon SQLite stores and the client Drift cache are the truth today; a lightweight relay hub (see Section 4) carries cross-node deltas.

```mermaid
graph TD
    subgraph Client["Flutter Client"]
        A["Drift SQLite - ~60 tables, local-first"]
        B["Zen Editor, media, RPG UI"]
    end
    subgraph Daemon["Host Daemon (Windows host)"]
        C["REST /api/v1/<domain> - JWT gate"]
        D["Per-module SQLite in data/"]
        E["Events WebSocket bus"]
        F["Web portal - Flutter web at /"]
    end
    subgraph Relay["Relay hub - repo-root server/ :8080"]
        G["POST /api/sync -> generic_vault.jsonl"]
        H["GET /ws - Yjs room relay with ACL"]
    end
    A -->|"poll + base64/gzip push"| C
    A <-->|"events"| E
    C <--> D
    F --> C
    C -->|"Funnel upstream :50051/:50052"| G
    H --> C
```

### Path 1: Obsidian File Mutation Lifecycle
1.  The user edits an Obsidian note inside their local directory using a standard Markdown editor.
2.  The client's asynchronous **File Watcher** detects the file change. On Windows, this leverages native `ReadDirectoryChangesW`. On Android, due to Android 11+ Scoped Storage (SAF) restrictions, the client uses a hybrid **ContentObserver** coupled with a low-impact background periodic directory poll.
3.  The client parses the YAML frontmatter block using safe regular expressions (defined in [[04 - LifeOS DevDocs/DATA_SCHEMAS|DATA_SCHEMAS]]).
4.  If metadata changes are found, corresponding update routines run inside the local **SQLite Cache** to sync metadata metrics.
5.  Continuous auto-saves from the client's internal markdown editor (e.g., Zen Editor) are seamlessly flushed to the Go daemon's `/api/markdown/sync` endpoint.

### Path 2: Structured Data (Habit/Task) Mutation Lifecycle
1.  The user toggles a habit completion checkbox inside the native Flutter application UI.
2.  The reactive Drift framework fires a database transaction writing the change into `habits` (setting `synced_at = NULL`).
3.  Simultaneously, a delta payload transaction is written to the `sync_queue` table.
4.  The background networking scheduler fires and checks connection status against the host daemon. If the connection is offline, deltas accumulate in SQLite. To prevent battery drain and db bloat:
    - **Payload Batching:** Transmits in batches of max 50 records per payload.
    - **Exponential Backoff:** Retries scale backoff dynamically on failure.
    - **Queue Compression/Eviction:** If pending deltas exceed 10,000, non-essential logs are compressed or pruned.
5.  Upon API acknowledgement, the client marks `sync_queue` states to `1` (Synced) and updates `synced_at` on the source records, avoiding infinite echo-loops.

### Path 3: Live Telemetry & Spatial UX Navigation
1.  **WebSocket Radar:** Location coordinate telemetry streams continuously via `tsnet` WebSockets to the mesh network, updating the UI heartbeat.
2.  **Spatial 3x3 Grid Engine:** Visual layouts run on a dynamic `FeatureRegistry` powered by an interactive Radial Dial, shifting layouts gracefully across the spatial grid.
3.  **Hybrid OTA Updates:** Silent checks ping the local Go daemon for rapid APK updates; failing that, fallback queries target GitHub releases to maintain client-backend binary parity.

---

## 4. Current State (August 2026)

The system in August 2026 runs at version **v1.5.0+2 (build 33)**.

### Web Portal
The daemon serves a Flutter web bundle at `/`, exposed over Tailscale Funnel at `https://lifeos-host.husky-forel.ts.net`. Access is gated by a JWT gate; sign-in uses OAuth (GitHub/Google) and is invite-only.

### Sync Relay Hub
A relay lives at the repository root in `server/` (port 8080):
- `POST /api/sync` persists inbound deltas to `generic_vault.jsonl`.
- `GET /ws` relays Yjs collaboration rooms, enforcing an ACL.

### Daemon
The host daemon listens on `:50051` and `:50052` as Tailscale Funnel upstreams and persists per-module SQLite databases under `data/` (e.g., `movies.db`, `media.db`, `books.db`, `gallery.db`, `zen.db`, `rpg.db`, `sync.db`). All domains are exposed as REST route groups under `/api/v1/<domain>`, per [[04 - LifeOS DevDocs/INTEGRATION_PLAN|INTEGRATION_PLAN]] (2026-08-11).

### Media Domains
- **Movies:** TMDB metadata pipeline.
- **Music:** yt-dlp downloads, m4a proxy streaming, lyrics.
- **Books:** four content sources plus LLM AI processing.
- **Gallery:** sha256/dHash smart picker.
- **Zen / Notes:** DB-backed filesystem for markdown notes.

### RPG Layer
A player progression layer covers XP, leveling, quests, illness/atrophy mechanics, and automations; star points are derived as `stars = points / 100`.

---

## 5. Performance & Resource Constraints

*   **Thread Safety:** The SQLite instance runs exclusively on the main app background thread. Watchers and networking execute on isolated system threads to prevent frame drops in the client UI.
*   **Battery Management (Android):** Networking cycles utilize aggressive scheduling policies. The `tsnet` tunnel is shut down when the app is placed in a deep background state, releasing system resources.
*   **Offline Operation:** If network connections fail or the tailnet is unavailable, operations execute seamlessly against SQLite and local files, queuing updates for processing when the mesh is restored.