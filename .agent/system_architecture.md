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
│   └── lib/                     # Client application state and interface logic
└── docs/                        # Specifications (System Source of Truth)
    ├── DATA_SCHEMAS.md          # Database tables, caching, and frontmatter patterns
    ├── EMBEDDED_NETWORK.md      # tsnet lifecycle and authentication logic
    └── SYNC_PROTOCOL.md         # Transactional field-level delta sync engine
```

---

## 2. Platform Target System Integration

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

## 3. Data Flow & Integration Lifecycle

The synchronization process bridges three major architectural nodes: the **Obsidian Vault Directory**, the **Local SQLite Database Cache**, and the **Self-Hosted Syncer Stack**.

```
   [Obsidian Vault (.md)]  <==================== (File Watcher / Parser)
             |
             |  (Read/Write Frontmatter Blocks)
             v
   [Local SQLite Cache (Drift)]  <==== (Delta Appender inside Transaction)
             |
             |  (Poll Pending state = 0 deltas)
             v
   [sync_queue Database Log]
             |
             |  (JSON Delta Payload Encrypted)
             v
    [Embedded tsnet Tunnel]
             |
             |  (WireGuard user-space tunnel)
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
2.  The client's asynchronous **File Watcher** (`ReadDirectoryChangesW` on Windows, `inotify` on Android) detects the file change trigger.
3.  The client parses the YAML frontmatter block using safe regular expressions (defined in `DATA_SCHEMAS.md`).
4.  If metadata changes are found, corresponding update routines run inside the local **SQLite Cache** to sync metadata metrics.

### Path 2: Structured Data (Habit/Task) Mutation Lifecycle
1.  The user toggles a habit completion checkbox inside the native Flutter application UI.
2.  The reactive Drift framework fires a database transaction writing the change into `habits` (setting `synced_at = NULL`).
3.  Simultaneously, a delta payload transaction is written to the `sync_queue` table.
4.  The background networking scheduler fires, checks connection status over the **Embedded tsnet** node, and sends the delta array to the backup relay.
5.  Upon API acknowledgement, the client marks `sync_queue` states to `1` (Synced) and updates `synced_at` on the source records.

---

## 4. Performance & Resource Constraints

*   **Thread Safety:** The SQLite instance runs exclusively on the main app background thread. Watchers and networking execute on isolated system threads to prevent frame drops in the client UI.
*   **Battery Management (Android):** Networking cycles utilize aggressive scheduling policies. The `tsnet` tunnel is shut down when the app is placed in a deep background state, releasing system resources.
*   **Offline Operation:** If network connections fail or the tailnet is unavailable, operations execute seamlessly against SQLite and local files, queuing updates for processing when the mesh is restored.
