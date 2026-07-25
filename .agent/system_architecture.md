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

## 2. Visual Architecture Diagram

```mermaid
flowchart TD

subgraph group_client["Flutter Client"]
  node_client_main["Client entry point<br/>Flutter bootstrap<br/>[main.dart]"]
  node_client_bootstrap["App bootstrap<br/>initialization<br/>[app_bootstrap.dart]"]
  node_client_shell["Main workspace shell<br/>Flutter UI"]
  node_feature_registry["Feature registry<br/>plugin registry"]
  node_module_router["Module router<br/>navigation"]
  node_local_db[("Local system of record<br/>Drift / SQLite<br/>[database.dart]")]
  node_client_sync["Client sync manager<br/>delta sync"]
  node_device_services{{"Device services<br/>platform boundary"}}
end

subgraph group_host["Trusted Host Daemon"]
  node_daemon_main["Host daemon entry point<br/>Go service<br/>[main.go]"]
  node_tailnet{{"Private mesh network<br/>Tailscale tsnet<br/>[tailnet.go]"}}
  node_auth_api["Auth API<br/>HTTP router<br/>[router.go]"]
  node_jwt_middleware["Bearer authorization<br/>JWT middleware<br/>[jwt.go]"]
  node_domain_router["Domain router<br/>module router<br/>[router.go]"]
  node_location_realtime["Location and live sharing<br/>real-time router<br/>[router.go]"]
  node_location_websockets["Location WebSockets<br/>streaming<br/>[websocket.go]"]
  node_automations["Geofence automations<br/>[automations.go]"]
  node_host_operations{{"Privileged host operations<br/>system router<br/>[router.go]"}}
  node_vault_watcher["Vault watcher<br/>markdown integration<br/>[watcher.go]"]
  node_lww_conflicts["LWW conflict resolution<br/>sync policy<br/>[lww.go]"]
  node_proxy{{"Optional edge proxy<br/>Caddy deployment"}}
end

subgraph group_sync["Optional Sync Service"]
  node_sync_server["Sync server entry point<br/>Go service<br/>[main.go]"]
  node_sync_hub[("Append-log sync hub<br/>delta persistence<br/>[sync_hub.go]")]
end

node_client_main -->|"starts"| node_client_bootstrap
node_client_bootstrap -->|"renders"| node_client_shell
node_client_bootstrap -->|"composes"| node_feature_registry
node_feature_registry -->|"registers modules"| node_module_router
node_client_shell -->|"reads and writes"| node_local_db
node_client_shell -->|"uses"| node_device_services
node_local_db -->|"produces deltas"| node_client_sync
node_client_sync -->|"syncs over"| node_tailnet
node_tailnet -->|"reaches"| node_daemon_main
node_daemon_main -->|"protects routes with"| node_jwt_middleware
node_auth_api -->|"issues and validates access"| node_jwt_middleware
node_jwt_middleware -->|"authorizes"| node_domain_router
node_domain_router -->|"routes location"| node_location_realtime
node_location_realtime -->|"triggers on geofences"| node_automations
node_location_realtime -->|"broadcasts updates"| node_location_websockets
node_location_websockets -->|"live streams"| node_client_shell
node_domain_router -->|"routes privileged actions"| node_host_operations
node_domain_router -->|"integrates vault activity"| node_vault_watcher
node_client_sync -.->|"optional sync target"| node_sync_server
node_sync_server -->|"persists through"| node_sync_hub
node_client_sync -.->|"reconciles conflicts"| node_lww_conflicts
node_proxy -.->|"optional proxy to"| node_daemon_main

click node_client_main "https://github.com/siaftoulis/lifeos/blob/main/client/lib/main.dart"
click node_client_bootstrap "https://github.com/siaftoulis/lifeos/blob/main/client/lib/app_bootstrap.dart"
click node_client_shell "https://github.com/siaftoulis/lifeos/blob/main/client/lib/life_os_main_stack.dart"
click node_feature_registry "https://github.com/siaftoulis/lifeos/blob/main/client/lib/core/feature_registry.dart"
click node_module_router "https://github.com/siaftoulis/lifeos/blob/main/client/lib/app_module_router.dart"
click node_local_db "https://github.com/siaftoulis/lifeos/blob/main/client/lib/database/database.dart"
click node_client_sync "https://github.com/siaftoulis/lifeos/blob/main/client/lib/database/custom_sync_manager.dart"
click node_daemon_main "https://github.com/siaftoulis/lifeos/blob/main/backend/host-daemon/main.go"
click node_tailnet "https://github.com/siaftoulis/lifeos/blob/main/backend/host-daemon/tailnet.go"
click node_auth_api "https://github.com/siaftoulis/lifeos/blob/main/backend/host-daemon/internal/auth/router.go"
click node_jwt_middleware "https://github.com/siaftoulis/lifeos/blob/main/backend/host-daemon/internal/auth/middleware/jwt.go"
click node_domain_router "https://github.com/siaftoulis/lifeos/blob/main/backend/host-daemon/internal/engine/router.go"
click node_location_realtime "https://github.com/siaftoulis/lifeos/blob/main/backend/host-daemon/internal/location/router.go"
click node_location_websockets "https://github.com/siaftoulis/lifeos/blob/main/backend/host-daemon/internal/location/websocket.go"
click node_automations "https://github.com/siaftoulis/lifeos/blob/main/backend/host-daemon/internal/location/automations.go"
click node_host_operations "https://github.com/siaftoulis/lifeos/blob/main/backend/host-daemon/internal/system/router.go"
click node_vault_watcher "https://github.com/siaftoulis/lifeos/blob/main/backend/host-daemon/internal/markdown/watcher.go"
click node_sync_server "https://github.com/siaftoulis/lifeos/blob/main/server/main.go"
click node_sync_hub "https://github.com/siaftoulis/lifeos/blob/main/server/sync_hub.go"
click node_lww_conflicts "https://github.com/siaftoulis/lifeos/blob/main/backend/host-daemon/internal/sync/lww.go"
click node_proxy "https://github.com/siaftoulis/lifeos/blob/main/backend/proxy/Caddyfile"

classDef toneNeutral fill:#f8fafc,stroke:#334155,stroke-width:1.5px,color:#0f172a
classDef toneBlue fill:#dbeafe,stroke:#2563eb,stroke-width:1.5px,color:#172554
classDef toneAmber fill:#fef3c7,stroke:#d97706,stroke-width:1.5px,color:#78350f
classDef toneMint fill:#dcfce7,stroke:#16a34a,stroke-width:1.5px,color:#14532d
classDef toneRose fill:#ffe4e6,stroke:#e11d48,stroke-width:1.5px,color:#881337
classDef toneIndigo fill:#e0e7ff,stroke:#4f46e5,stroke-width:1.5px,color:#312e81
classDef toneTeal fill:#ccfbf1,stroke:#0f766e,stroke-width:1.5px,color:#134e4a
class node_client_main,node_client_bootstrap,node_client_shell,node_feature_registry,node_module_router,node_local_db,node_client_sync,node_device_services toneBlue
class node_daemon_main,node_tailnet,node_auth_api,node_jwt_middleware,node_domain_router,node_location_realtime,node_location_websockets,node_automations,node_host_operations,node_vault_watcher,node_lww_conflicts,node_proxy toneAmber
class node_sync_server,node_sync_hub toneMint
```

---

## 3. Platform Target System Integration

The application compiles into native code targets, binding underlying OS capabilities directly.

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

## 4. Data Flow & Integration Lifecycle

The synchronization process bridges three major architectural nodes: the **Obsidian Vault Directory**, the **Local SQLite Database Cache**, and the **Self-Hosted Syncer Stack**.

### Local Sidecar Side vs. Remote Mesh Topology
The system enforces a localized split-plane topology:
1. **Local Go Daemon (Sidecar):** Runs as a background service on the desktop host to directly execute local OS shell routines (Hyper-V control, WOL) and handle local vault disk mutations (POST `/api/markdown/sync`) to bypass remote latency.
2. **Remote Docker Stack (Relay & PostgreSQL):** The central source of truth for relational state, running in isolated containers (behind Caddy and OAuth2 authentication) on the remote private Tailnet, reachable only through the embedded `tsnet` tunnel.

```
   [Obsidian Vault (.md)]  <==================== (File Watcher / Parser)
             |
             |  (Read/Write Frontmatter Blocks via Local Go Daemon on Port 8080)
             v
   [Local SQLite Cache (Drift)]  <==== (Delta Appender inside Transaction)
             |
             |  (Poll Pending state = 0 deltas)
             v
   [sync_queue Database Log]
             |
             |  (LWW State Vector & GZIP/Base64 Delta Chunk)
             v
    [Embedded tsnet Tunnel]
             |
             |  (WireGuard user-space tunnel to Port 80)
             v
   [Reverse Proxy (Caddy/Nginx)]
             |
             |  (Private Tailnet Route)
             v
   [Docker Sync Server Backend]
             |
             v
     [PostgreSQL Server]
```

### Path 1: Obsidian File Mutation Lifecycle
1.  The user edits an Obsidian note inside their local directory using a standard Markdown editor.
2.  The client's asynchronous **File Watcher** detects the file change. On Windows, this leverages native `ReadDirectoryChangesW`. On Android, due to Android 11+ Scoped Storage (SAF) restrictions, the client uses a hybrid **ContentObserver** coupled with a low-impact background periodic directory poll.
3.  The client parses the YAML frontmatter block using safe regular expressions (defined in `DATA_SCHEMAS.md`).
4.  If metadata changes are found, corresponding update routines run inside the local **SQLite Cache** to sync metadata metrics.
5.  Continuous auto-saves from the client's internal markdown editor (e.g., Zen Editor) are seamlessly flushed to the Go daemon's `/api/markdown/sync` endpoint.

### Path 2: Structured Data (Habit/Task) Mutation Lifecycle
1.  The user toggles a habit completion checkbox inside the native Flutter application UI.
2.  The reactive Drift framework fires a database transaction writing the change into `habits` (setting `synced_at = NULL`).
3.  Simultaneously, a delta payload transaction is written to the `sync_queue` table.
4.  The background networking scheduler fires and checks connection status over the **Embedded tsnet** node. If the connection is offline, deltas accumulate in SQLite. To prevent battery drain and db bloat:
    - **Payload Batching:** Transmits in batches of max 50 records per payload.
    - **Exponential Backoff:** Retries scale backoff dynamically on failure.
    - **Queue Compression/Eviction:** If pending deltas exceed 10,000, non-essential logs are compressed or pruned.
5.  Upon API acknowledgement, the client marks `sync_queue` states to `1` (Synced) and updates `synced_at` on the source records, avoiding infinite echo-loops.

### Path 3: Live Telemetry & Spatial UX Navigation
1.  **WebSocket Radar:** Location coordinate telemetry streams continuously via `tsnet` WebSockets to the mesh network, updating the UI heartbeat.
2.  **Spatial 3x3 Grid Engine:** Visual layouts run on a dynamic `FeatureRegistry` powered by an interactive Radial Dial, shifting layouts gracefully across the spatial grid.
3.  **Hybrid OTA Updates:** Silent checks ping the local Go daemon for rapid APK updates; failing that, fallback queries target GitHub releases to maintain client-backend binary parity.

---

## 5. Performance & Resource Constraints

*   **Thread Safety:** The SQLite instance runs exclusively on the main app background thread. Watchers and networking execute on isolated system threads to prevent frame drops in the client UI.
*   **Battery Management (Android):** Networking cycles utilize aggressive scheduling policies. The `tsnet` tunnel is shut down when the app is placed in a deep background state, releasing system resources.
*   **Offline Operation:** If network connections fail or the tailnet is unavailable, operations execute seamlessly against SQLite and local files, queuing updates for processing when the mesh is restored.
