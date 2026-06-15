# Raw Subagent Research Reports

This document contains the exact, unedited output from the three AI subagents that analyzed the LifeOS codebase on June 15, 2026. 

---

## 1. Vault Documentation Analyst Report

### 1. Overall LifeOS Vision & Philosophy

LifeOS is a **local-first, offline-first, multi-platform personal operating system** built as a monorepo (`lifeos-monorepo/`) with a Flutter client (Windows + Android), a Go backend daemon, and a self-hosted Docker sync server. The core philosophy:

- **Vault-Centric:** An Obsidian Vault (`vault/`) is the definitive source of truth for all documentation, specs, and logs. Maximum portability, offline capability, and human readability.
- **Zero-Exposure Mesh:** All networking happens over embedded Tailscale (`tsnet`) user-space nodes — no public internet exposure, no open firewall ports.
- **Spatial UI Engine:** The app uses a navigable spatial 3x3 grid ("tiles") with a radial dial for layout switching. On Android, it can replace the default launcher entirely (`android.intent.category.HOME`).
- **Gamification Core:** Everything feeds into the Point Star System — a behavioral ledger that rewards productive actions and penalizes leisure, gating access to external apps and smart home devices.
- **Everforest Design Language:** All UIs use a strict Everforest Minimalist Flat-Line theme (bg0 deep charcoal, bg1 dark charcoal, 1px borders in bg2, beige text headers, 16px rounded cards, no gradients/transparency blur, 0.9x scale tap feedback).
- **No Emojis** rule across all documentation.
- **Subagent Development Model:** Work is delegated to Alpha, Beta, and Gamma subagents with defined scopes.

### 2. Complete List of All 20 Planned Modules/Tiles (from `01 - Tiles/`)

| # | Tile Name | Status | Category |
|---|-----------|--------|----------|
| 1 | **Home Screen** | Concept Defined / Future Dev Planned | Core & Interface |
| 2 | **Preferences Setting Tab** | Concept Defined | Core & Interface |
| 3 | **Obsidian Zen Editor** | UI Built / Core Logic in Development | Core & Interface |
| 4 | **Calendar Habit Task Manager** | Conceptual Phase / Planning | Productivity |
| 5 | **Project Infinity** | Concept Defined | Productivity |
| 6 | **Flashcards** | Concept Defined | Productivity |
| 7 | **Knowledge Base** | Concept Defined | Productivity |
| 8 | **Photo Video Gallery** | Concept Defined | Media & Culture |
| 9 | **Movie Library** | Concept Defined | Media & Culture |
| 10 | **Book Library** | Concept Defined | Media & Culture |
| 11 | **Music Library** | Concept Defined | Media & Culture |
| 12 | **Virtual Machine Management** | Conceptual Phase / Design Stage | Environment |
| 13 | **Cloud & Fake Virtual Machine** | Concept Defined | Environment |
| 14 | **Maps & Live Tracking** | **Implementation Phase** — REST API, WebSocket, Geofence Active | Maps & Tracking |
| 15 | **Home Management** | Concept Defined | System Control |
| 16 | **Dark Web Management** | Concept Defined | System Control |
| 17 | **Point Star System** | Conceptual Phase / Design & Planning | System Control |
| 18 | **YouTube Client** | Concept Defined | System Control |
| 19 | **Banking System** | Conceptual Phase / Design & Planning | Financials |
| 20 | **Accounting** | Concept Defined | Financials |

**Actually built/active components** (from sprint data and tile statuses):
- **Maps & Live Tracking** — REST API, WebSocket broker, geofence haversine engine, and Flutter dashboard all operational
- **Obsidian Zen Editor** — UI built, core logic in development
- **Host Daemon (Infrastructure Control)** — Hyper-V bridges, WOL, VM status queries all completed
- **Core App UI** — Responsive shell, habit matrix, Hyper-V card, DevDocs webview all completed
- **Widget System** — Android AppWidgetProvider, Windows frameless overlay, multi-window lifecycle all completed
- **Sync Backend** — Go GZIP pool, `/api/sync/push` router, atomic mutex DB writer all completed
- **Auto-Update** — Go daemon APK router, client UpdateManager with streaming downloader completed
- **Test Environment** — Local OTA deployment with QR code, wireless ADB pairing completed
- **E2E Validation** — Live point-to-point sync over Tailscale mesh verified

### 3. Point Star Gamification System — Rules & Mechanics

**Core Concept:** Central behavioral ledger and gamification engine for daily productivity, financial discipline, study routines, and family coordination.

**Point Awards (from DATA_SCHEMAS.md):**
| Action | Points |
|--------|--------|
| Habit completion (`is_completed` toggle) | +5 |
| Calendar meeting attended | +10 |
| Environment telemetry sync | +2 |
| Knowledge topic completed | +5 |
| Bookmark / location track logged | +2 |
| Movie review saved | +5 |
| Lyrics translation study check | +2 |
| Active note editing (per hour in Zen Editor) | +5 |
| 5 media assets uploaded (Photo Gallery) | +1 |
| Daily vocabulary word reviewed | +1 |
| Daily trivia entry completed | +2 |
| **YouTube consumption (per 30 min)** | **-10** |

**Additional rules from tile specs:**
- Standard task/habit completion: +1 pt (with streak multipliers)
- High-priority task completion: +5 pts
- Neglecting a scheduled habit/chore: -2 pts
- Launching external Android apps: costs Star Points (deducted via `PointsDao`)

**Key Mechanics:**
1. **Global Module Listeners:** Central collector receiving triggers from ALL other LifeOS modules
2. **Family Leaderboards:** Real-time comparison between family members; highest monthly score gets decision privileges (e.g., vacation choice)
3. **Voucher Redemption Store:** Stars redeemable for real rewards (e.g., 1000 stars = €10 pocket money). Ticket-roll UI.
4. **Dynamic Privilege Lockouts:** If score falls below thresholds, automated webhooks lock entertainment access (smart TV via Home Management, external apps)
5. **Point-Gated App Drawer:** On Android, launching ANY external app (Instagram, Browser, etc.) deducts points
6. **Behavioral Allowance Split:** Banking system splits the "silly things" leisure budget based on Star Point ratios between family members
7. **No-Code Rule Configurator:** Flutter dashboard to add custom rules, set multipliers, define penalties without code changes
8. **Server-Authoritative LWW:** The backend is the ultimate truth for point ledger balances; client changes are queued as deltas

**Database Tables:** `system_users` (balances), `point_rules` (configurable rules per module), `points_ledger` (event history), `vouchers` (redeemable store)

**API Endpoints:**
- `GET /api/v1/points/leaderboard` — Leaderboard scores
- `POST /api/v1/points/ledger` — Log a score delta
- `POST /api/v1/points/vouchers/redeem` — Redeem a voucher

### 4. Sync Protocol Design

**Architecture:** Simplified local-first dirty-flag synchronization (full field-level CRDT sync is a long-term target).

**Current Implementation:**
1. **Relational Data (habits, tasks, etc.):**
   - Tables use `is_dirty` boolean flags directly (not a separate sync_queue interceptor)
   - 15-second polling cycle queries `WHERE is_dirty = 1`
   - Dirty rows serialized to JSON → GZIP compressed → Base64 encoded
   - Pushed via `POST /api/sync/push` to port 8080 on remote Docker server
   - On success: `is_dirty = 0`, process inbound modifications
   - On failure: retain dirty state, retry next cycle

2. **Markdown Notes:**
   - Full-text document overwrite (not diffed)
   - Client saves locally via `MarkdownStorage.saveNote()`
   - Pushes filename + full content to Go daemon's `/api/markdown/sync`
   - Host daemon does `os.WriteFile` directly to vault directory

3. **Conflict Resolution:**
   - **Relational data:** Entity-level Last-Write-Wins (LWW) using `updated_at` timestamps in atomic SQLite transactions
   - **Markdown:** Direct overwrite (no merge)
   - **Point Star ledger:** Server-Authoritative LWW (server is ultimate truth)
   - **YouTube downloads:** Client-driven LWW
   - **Future:** Sequence CRDTs for concurrent multi-user document editing

4. **Resilience:**
   - Payload batching: max 50 records per push
   - Exponential backoff on failure
   - Queue compression/eviction if pending deltas exceed 10,000
   - Full offline operation with queue accumulation

### 5. Network Architecture (Tailscale Mesh)

**Core:** Embedded user-space Tailscale via `tsnet` library — no TUN/TAP device, no admin privileges needed.

**Compile Targets:**
- **Windows:** C-archive DLL (`tsnet_client.dll`) via Cgo, integrated into Flutter C++ runner CMake
- **Android:** Java Archive (`tsnet_client.aar`) via `gomobile bind`, embedded in Gradle

**6-State Connection Machine:** OFFLINE → INITIALIZING → AUTHENTICATING → CONNECTING → CONNECTED → TEARDOWN

**Auth Flow:**
- Windows: `CredReadW` reads from Windows Credential Manager (`LifeOS:Tailscale:AuthKey`)
- Android: Jetpack Security `EncryptedSharedPreferences` with AES256_GCM master key
- Fallback: Pending Setup notification if no key exists

**Traffic Segregation (Port Map):**

| Service | Port | Network | Protocol |
|---------|------|---------|----------|
| Host Daemon API & WebSocket | 50051 | Localhost | HTTP/WS |
| Relational Sync | 8080 | Embedded tsnet | HTTP/JSON |
| Identity Proxy (OAuth2) | 4180 | Docker Mesh | HTTP |
| RustDesk Relay | 21115-21119 | Embedded tsnet | TCP/UDP |
| Sunshine/Moonlight GPU Stream | 47989-47990 | Embedded tsnet | TCP/UDP |
| OTA Server | 50051/443 | Localhost/WAN | HTTP/HTTPS |
| Web Fail-Safe (Caddy) | 80/443 | Public Tunnel | HTTPS |

**Split-Plane Topology:**
- **Local Go Daemon (Sidecar):** Port 50051, handles Hyper-V, WOL, vault disk mutations, media streaming
- **Remote Docker Stack:** PostgreSQL + Sync Server behind Caddy + OAuth2, reachable only via tsnet tunnel

### 6. Security Model

The `SECURITY_MODEL.md` file appears to be corrupted/placeholder (contains garbled characters). However, security is comprehensively documented across other files:

**Web Fail-Safe Layer (Zero-Trust Proxy):**
- For accessing LifeOS from restricted/foreign machines where native client can't be installed
- **Inbound tunneling** via Tailscale Funnel or Zrok Public Share (zero open firewall ports)
- **OAuth2 Proxy** (Google/GitHub) sits at the edge — no request reaches the app without a cryptographically signed cookie
- Strict email whitelist (`authenticated_emails_file`) — owner's email only
- Cookie hardening: `secure=true`, `httponly=true`, `samesite=lax`
- Stolen URL? → Stopped by SSO redirect. Brute force? → Delegated to Google/GitHub 2FA + rate limiting
- Web portal has bounded session context — cannot execute host admin commands

**Host Daemon Security:**
- Strictly typed action payloads (`START_VM`, `STOP_VM`, `GET_VMS`, `TRIGGER_WOL` — no arbitrary code execution)
- HMAC-SHA256 signatures on every request
- Epoch millisecond timestamps to prevent replay attacks

**Credential Storage:**
- Windows: Win32 Credential Manager API (`CredReadW`)
- Android: Hardware-backed Android Keystore with AES256_GCM encrypted SharedPreferences

### 7. Current Sprint Priorities

**12 Macro Tasks tracked in `current_sprint.json`:**

| Macro Task | Status | Completed/Total Subtasks |
|------------|--------|--------------------------|
| Initialize Environment & Documentation | Planning | 11/21 |
| INFRASTRUCTURE-CONTROL | Planning | 6/6 ✅ |
| WIDGET-SYSTEM | Planning | 5/5 ✅ |
| CORE-APP-UI | (active) | 4/4 ✅ |
| TEST-ENVIRONMENT | (active) | 2/2 ✅ |
| GIT-BACKUP | (active) | 2/2 ✅ |
| COUCHDB-SYNC | Planning | 0/2 |
| CUSTOM-SYNC | Completed | 0/2 (subtasks still pending) |
| BACKEND-SYNC | Completed | 2/2 ✅ |
| E2E-VALIDATION | Completed | 2/2 ✅ |
| UI-FEATURES | Completed | 1/2 |
| ARCH-EXT | Completed | 1/1 ✅ |
| AUTO-UPDATE | Completed | 2/2 ✅ |

**Key pending work items:**
- `WATCH-004`: Frontmatter metadata updater and clean formatter
- `NET-001/002`: Go tsnet DLL compilation for Windows & AAR for Android
- `NET-003/004`: Secure credential storage (Win32 CredReadW, Android EncryptedSharedPreferences)
- `SYNC-002/003/004`: Drift change interceptor, LWW algorithm, sync polling scheduler
- `PROXY-001/002/003`: OAuth2 Proxy setup, email whitelist, Tailscale Funnel/zrok share
- `SYN-001/002` (COUCHDB-SYNC): CouchDB replication client, background mutation hooks
- `SYN-001/002` (CUSTOM-SYNC): Proprietary sync encoder, inbound processor
- `FEAT-001`: High-performance local Markdown reader and link tokenizer

### Tile Spec Format

Each tile document follows a consistent structure:
1. **Header** with Status badge and linked modules
2. **Concept & Vision** — Philosophy and core features
3. **Work Done So Far** — Current implementation state
4. **Current Focus & Actions** — Active development items
5. **Next Steps & Future Roadmap** — Planned features
6. **Interaction Flows & Diagrams** — Mermaid flow diagrams
7. **Technical Specs** links — to `What to Build`, `How to Build`, `What to Do` in `02 - Technical Specs/`

Each Technical Spec has: SQLite schemas, REST API endpoints, Flutter widget component registries, and step-by-step subagent implementation instructions.

---

## 2. Client Architecture Analyst Report

## App Initialization Sequence (`main.dart`)

1. `WidgetsFlutterBinding.ensureInitialized()`
2. Initialize `PreferencesService` (loads JSON prefs from local file)
3. Initialize `AppDatabase` (Drift/SQLite) — `LazyDatabase` opens on first access
4. Set Android high refresh rate via `FlutterDisplayMode`
5. **Restore Auth Session**: If `rememberMe` is true and token exists, calls `AuthService.restoreSession()` which validates token against daemon `/api/v1/auth/validate`
6. Run `LifeOSApp` widget
7. If not authenticated → show **Login Screen** with server URL config + username/password
8. If authenticated → show **AppShell** (main spatial grid dashboard)
9. Start **notification polling timer** — polls `/api/v1/notifications` every 4 seconds, deduplicates and inserts into local `local_notifications` table
10. Initialize **LocationTrackerPlugin** for background GPS streaming

## Authentication Flow

### Login:
1. User enters server URL (saved to prefs), username, password
2. `AuthService.login()` calls `POST /api/v1/auth/login` with JSON body
3. Server returns `{ token, user: { id, username, role, displayName, status, avatarAsset } }`
4. Token + user profile saved to `PreferencesService`
5. If "Remember Me" checked → persisted across app restarts
6. App transitions to `AppShell`

### Session Restore:
1. On app start, check `rememberMe` flag and stored token
2. Call `GET /api/v1/auth/validate` with `Authorization: Bearer <token>` header
3. If valid → auto-login. If invalid → show login screen.

### Logout:
1. `AuthService.logout()` clears token, user profile, and `rememberMe` from prefs
2. App returns to login screen

## All Registered Modules/Features (`feature_registry.dart`)

The feature registry maps string IDs to feature metadata (name, icon, description). From the code:

| Module ID | Name | Icon |
|-----------|------|------|
| `home_screen` | Home Screen | `Icons.home` |
| `obsidian_zen_workspace` | Obsidian Zen Workspace | `Icons.edit_note` |
| `knowledge_base` | Knowledge Base | `Icons.menu_book` |
| `accounting` | Accounting | `Icons.account_balance` |
| `banking_system` | Banking System | `Icons.account_balance_wallet` |
| `calendar_habit_task` | Calendar & Habits | `Icons.calendar_today` |
| `flashcards` | Flashcards | `Icons.style` |
| `project_infinity` | Project Infinity | `Icons.rocket_launch` |
| `book_library` | Book Library | `Icons.local_library` |
| `movie_library` | Movie Library | `Icons.movie` |
| `music_library` | Music Library | `Icons.library_music` |
| `photo_video_gallery` | Photo/Video Gallery | `Icons.photo_library` |
| `youtube_client` | YouTube Client | `Icons.smart_display` |
| `cloud_vm` | Cloud & Fake VM | `Icons.cloud` |
| `vm_management` | VM Management | `Icons.computer` |
| `dark_web_management` | Dark Web Management | `Icons.security` |
| `home_management` | Home Management | `Icons.home_work` |
| `maps_live_tracking` | Maps & Live Tracking | `Icons.map` |
| `point_star_system` | Point Star System | `Icons.star` |
| `preferences_setting` | Preferences & Settings | `Icons.settings` |
| `live_sharing` | Live Sharing | `Icons.share` |
| `location_tracker` | Location Tracker | `Icons.location_on` |

**22 registered features** total.

## All Database Tables (`database.dart`)

The Drift database defines these tables:

| Table Name | Purpose |
|------------|---------|
| `obsidian_files` | Vault markdown file metadata |
| `obsidian_links` | Inter-note link graph |
| `knowledge_entries` | Knowledge base articles |
| `accounting_transactions` | Financial transactions |
| `banking_accounts` | Bank account records |
| `calendar_events` | Calendar entries |
| `habits` | Habit definitions |
| `tasks` | Task/todo items |
| `flashcard_decks` | Flashcard deck metadata |
| `flashcards` | Individual flashcard Q&A |
| `projects` | Project management entries |
| `books` | Book library catalog |
| `movies` | Movie library catalog |
| `music_tracks` | Music library catalog |
| `photos` | Photo gallery metadata |
| `videos` | Video gallery metadata |
| `youtube_subscriptions` | YT channel subscriptions |
| `cloud_vms` | Virtual machine instances |
| `docker_containers` | Docker container state |
| `iot_devices` | Smart home device registry |
| `point_star_balances` | User point balances |
| `point_star_ledger` | Point transaction history |
| `local_notifications` | Notification storage |
| `maps_location_history` | GPS location log |
| `maps_geofences` | Geofence zone definitions |
| `sync_deltas` | Outbound sync change queue |
| `sync_state` | Sync metadata/cursors |

**27 tables** total.

## All Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  flutter: sdk
  desktop_multi_window: ^0.2.0
  drift: any
  web_socket_channel: ^3.0.3
  path_provider: ^2.1.5
  http: ^1.2.0
  url_launcher: ^6.3.2
  installed_apps: ^2.1.1
  geolocator: ^14.0.3
  flutter_map: ^8.3.0
  latlong2: ^0.9.1
  flutter_display_mode: ^0.6.0

dev_dependencies:
  flutter_test: sdk
  drift_dev: any
  build_runner: any
```

## All Plugins (`client/lib/plugins/`)

| Plugin | File(s) | Purpose |
|--------|---------|---------|
| **Location Tracker** | `location_tracker/location_tracker_plugin.dart` | Background GPS streaming via `geolocator`, reports to daemon every 10m movement |
| **Live Sharing** | `live_sharing/live_sharing_plugin.dart` | WebSocket-based real-time data sharing between devices |
| **Gallery** | `gallery/gallery_plugin.dart` | Local photo/video indexing and display |
| **Map View** | `map_view/map_view_plugin.dart` | OpenStreetMap tile rendering abstraction |
| **Markdown** | `markdown/markdown_plugin.dart` | Vault markdown file parsing, frontmatter extraction, link tokenization |
| **Settings** | `settings/settings_plugin.dart` | Platform-specific settings integration |

**6 plugins** total.

## All UI Widgets (by folder)

### `home_screen/`
| Widget | File | Description |
|--------|------|-------------|
| **Clock Widget** | `clock_widget.dart` | Real-time HH:MM clock with date, 1-second refresh |
| **Lock Screen Overlay** | `lock_screen_overlay.dart` | Full lock screen with swipe-up gesture, animated login form with username/password fields, "Remember Me", error display. 299 lines. |
| **Notifications Feed** | `notifications_feed.dart` | Category-color-coded notification cards (SYSTEM=blue, HABIT=aqua, SECURITY=red, FINANCIAL=green) with icons and timestamps. 105 lines. |

### `maps_live_tracking/`
| Widget | File | Description |
|--------|------|-------------|
| **Maps Dashboard** | `maps_dashboard_widget.dart` | Main maps view — WebSocket live feed, OSM map, FAB controls for navigation/geofence/locate-me. 164 lines. |
| **OSM Map** | `osm_map_widget.dart` | flutter_map with OSM tiles, person markers, my-location blue dot, geofence polygons. 119 lines. |
| **Dashboard Header** | `maps_dashboard_header.dart` | Top bar with LIVE/OFFLINE WebSocket status indicator. 48 lines. |
| **Live Feed Preview** | `maps_live_feed_preview.dart` | Horizontal scrollable feed showing device IDs and coordinates. 48 lines. |
| **Report Banner** | `maps_report_banner.dart` | Status banner showing geofence trigger count. 46 lines. |
| **Navigation Overlay** | `navigation_overlay.dart` | Floating panel with start/destination inputs and "Start Navigation" button. 79 lines. |
| **Geofence Drawer** | `geofence_drawer_overlay.dart` | Bottom drawer listing geofence zones with toggle switches and "Draw New" mode. 80 lines. |
| **Geofence Editor** | `geofence_editor_widget.dart` | List view of geofences with lat/lon/radius display. 62 lines. |
| **Dark Radar** | `dark_radar_widget.dart` | Animated custom-painted radar sweep with concentric circles and target beacons. 89 lines. |

### `point_star_system/`
| Widget | File | Description |
|--------|------|-------------|
| **Point Star Dashboard** | `point_star_dashboard.dart` | Family leaderboard + real-time transaction ledger with ±points notation. 162 lines. |
| **Voucher Redeemer** | `voucher_redeemer_panel.dart` | Bottom sheet rewards store with color-tiered voucher cards and redemption flow. 246 lines. |
| **Gated Module Wrapper** | `gated_module_wrapper.dart` | Blurred+glassmorphic access-restricted overlay for point-locked modules. 116 lines. |
| **Leaderboard Card** | `leaderboard_card.dart` | Ranked user card with gold/silver/bronze coloring. 50 lines. |

### `preferences_setting/`
| Widget | File | Description |
|--------|------|-------------|
| **Preferences Dashboard** | `preferences_dashboard_view.dart` | Main settings hub with navigation to sub-screens. |
| **Android Launcher** | `android_launcher_widget.dart` | Full launcher replacement — app grid/folder view, AI-categorized apps, point-gated launching. 481 lines. |
| **Grid Configurator** | `grid_configurator_widget.dart` | Spatial grid layout size configuration (columns × rows). |
| **Admin Console** | `admin_console_widget.dart` | User management — create users with username/password/role. 143 lines. |
| **My Profile** | `my_profile_widget.dart` | Edit display name, status, avatar. Logout/lock button. 131 lines. |
| **Tailscale Node Monitor** | `tailscale_node_monitor_widget.dart` | Mesh network status — node names, IPs, online/offline. 39 lines. |

### Other widgets
| Widget | File | Description |
|--------|------|-------------|
| **Configurator** | `configurator.dart` | Master widget router — maps moduleId strings to concrete widget instances. |
| **App Shell** | `app_shell.dart` | Root layout shell — initializes location tracker, renders spatial grid of module cards. |
| **VM Card** | `vm_card.dart` | Virtual machine status card with start/stop/connect controls. |
| **Desktop Widget Manager** | `desktop_widget_manager.dart` | Multi-window management for desktop platforms. |
| **Diagnostics Controller** | `diagnostics_controller.dart` | Runtime diagnostics overlay for debugging. |

## API Client (`api_client.dart`)

### Endpoints Used:
| Method | Path | Purpose |
|--------|------|---------|
| `POST` | `/api/v1/auth/login` | User login |
| `POST` | `/api/v1/auth/register` | User registration |
| `GET` | `/api/v1/auth/validate` | Token validation |
| `GET` | `/api/v1/system/status` | System health check |
| `GET` | `/api/v1/notifications` | Poll notifications |
| `POST` | `/api/v1/radar/report` | Submit GPS location |
| Various | `/api/v1/points/*` | Points system |
| Various | `/api/v1/sync/*` | Data synchronization |

### Features:
- `discoverBaseUrl()` — Auto-discovers sync server on port 8080
- `discoverDaemonUrl()` — Auto-discovers host daemon on port 50051
- Bearer token injection via `_authHeaders()` on all authenticated requests
- Configurable server URL stored in preferences

---

## 3. Backend Infrastructure Analyst Report

## 1. All API Endpoints

### Host Daemon (Port `:50051`)

#### Auth Module (`/api/v1/auth/`)
| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/auth/login` | Authenticate user with username/password, returns token + user profile |
| `POST` | `/api/v1/auth/lock` | Lock the current session |
| `GET` | `/api/v1/auth/users` | List all registered users (returns array of user objects without passwords) |
| `POST` | `/api/v1/auth/users` | Create a new user (username, password, role) |
| `PUT` | `/api/v1/auth/profile` | Update user profile (displayName, status, avatarAsset) |
| `GET` | `/api/v1/auth/validate` | Validate session token from `Authorization: Bearer <token>` header |
| `GET` | `/api/v1/notifications` | Get time-dripped notifications (new one every 15 seconds from template list) |

#### Location Module (`/api/v1/radar/`)
| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/radar/geofences` | List all defined geofence zones |
| `POST` | `/api/v1/radar/geofences` | Create a new geofence zone (name, type, center, radius/polygon, automations) |
| `POST` | `/api/v1/radar/report` | Report GPS location — runs geofence proximity checks and triggers automations |
| `GET` | `/api/v1/radar/live` | WebSocket upgrade — real-time location broadcast to all connected clients |
| `POST` | `/api/v1/radar/routing` | Request route between two coordinates |

#### Points Module (`/api/v1/points/`)
| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/points/leaderboard` | Family leaderboard — all users ranked by total points |
| `GET` | `/api/v1/points/ledger` | Transaction history — all point additions and deductions |
| `POST` | `/api/v1/points/vouchers/redeem` | Redeem a voucher — deducts points, triggers TV Lock if balance goes negative |

#### System Module (`/api/v1/system/`)
| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/system/status` | System health — hostname, uptime, OS, CPU cores, memory stats, Go runtime |
| `GET` | `/api/v1/system/settings` | Get system settings (with CHILD role intercept — returns 403) |
| `POST` | `/api/v1/system/settings` | Update system settings (with CHILD role intercept) |
| `GET` | `/api/v1/system/nodes` | Tailscale mesh node status — runs `tailscale status --json`, falls back to mock data |
| `POST` | `/api/v1/system/reboot` | Reboot the host machine (`shutdown /r /t 5` on Windows, `reboot` on Linux) |
| `POST` | `/api/v1/system/shutdown` | Shutdown the host machine (`shutdown /s /t 5` on Windows, `poweroff` on Linux) |
| `GET` | `/api/v1/system/services` | List running services (`sc query` on Windows, `systemctl` on Linux) |
| `GET` | `/api/v1/system/logs` | Get system logs (`Get-EventLog` on Windows, `journalctl` on Linux) |
| `POST` | `/api/v1/system/apps/categorize` | AI-powered app categorization — sends app names to Gemini API, falls back to local heuristics |
| `GET` | `/api/v1/system/diagnostics` | Runtime diagnostics — goroutines, memory stats, GC info |

#### Sync Module (`/api/v1/sync/`)
| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/sync` | Submit sync deltas (change records) to the daemon |

#### Infrastructure
| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/wol` | Wake-on-LAN — sends magic packet to wake a device by MAC address |

**Total: 24 API endpoints** across 5 modules.

## 2. Go Modules/Dependencies

From `backend/host-daemon/go.mod`:

| Dependency | Version | Purpose |
|------------|---------|---------|
| `tailscale.com` | v1.82.5 | Embedded Tailscale (tsnet) for mesh networking |
| `github.com/gorilla/websocket` | v1.5.3 | WebSocket server for real-time location/live sharing |
| `golang.org/x/crypto` | v0.38.0 | bcrypt password hashing |

Plus standard library usage: `net/http`, `encoding/json`, `os/exec`, `runtime`, `sync`, `crypto/rand`, `fmt`, `log`, `strings`, `math`, `io`, `time`.

The daemon is remarkably lean — only 3 external dependencies.

## 3. Tailscale/tsnet Integration

From `backend/host-daemon/main.go` (lines 16-28):

```go
tsServer := new(tsnet.Server)
tsServer.Hostname = "lifeos-host"
tsServer.Dir = "./tsnet-state"
tsServer.Logf = func(format string, args ...any) {}

if err := tsServer.Start(); err != nil {
    log.Fatalf("tsnet failed to start: %v", err)
}
defer tsServer.Close()

ln, err := tsServer.Listen("tcp", ":50051")
```

### Key Details:
- **Embedded tsnet** — no separate Tailscale daemon required
- **Hostname**: `lifeos-host` — identifies this node on the tailnet
- **State directory**: `./tsnet-state/` — stores WireGuard keys, node identity
- **Port**: `:50051` — all API endpoints served over the Tailscale network
- **Silent logging** — Tailscale internal logs suppressed
- The HTTP server (`http.DefaultServeMux`) listens on the tsnet listener, meaning **all traffic is encrypted via WireGuard**
- First run opens a browser for Tailscale authentication (OAuth)

## 4. CI/CD Pipeline (`release.yml`)

**Trigger**: Push of any tag matching `v*`

### Job 1: `build-android` (ubuntu-latest)
1. Checkout repository
2. Setup Java 17 (Zulu distribution)
3. Setup Flutter (stable channel)
4. **Scaffold & Patch**: Backup AndroidManifest → `flutter create` → restore manifest → strip local JVM paths
5. `flutter pub get`
6. `flutter build apk --release`
7. Upload `app-release.apk` as artifact

### Job 2: `build-windows` (windows-latest)
1. Checkout repository
2. Setup Flutter (stable channel)
3. Scaffold missing project files via `flutter create`
4. `flutter pub get`
5. `flutter build windows --release`
6. `Compress-Archive` → `lifeos-windows-release.zip`
7. Upload ZIP as artifact

### Job 3: `publish-release` (ubuntu-latest, depends on both builds)
1. Checkout repository
2. Download APK artifact
3. Download Windows ZIP artifact
4. Generate release notes markdown from `version.json` build number
5. Publish GitHub Release via `softprops/action-gh-release` with both binaries attached

## 5. Deployment Architecture

```
┌─────────────────────────────────────────────────┐
│                 Tailscale Mesh Network           │
│                  (WireGuard encrypted)           │
│                                                  │
│  ┌──────────────┐    ┌───────────────────────┐  │
│  │ Flutter Client│    │  Host Daemon (Go)     │  │
│  │ (Android/Win) │◄──►│  Port :50051          │  │
│  │               │    │  tsnet hostname:      │  │
│  │ - Auth        │    │    lifeos-host        │  │
│  │ - Spatial Grid│    │                       │  │
│  │ - 22 Modules  │    │  Modules:             │  │
│  │ - Drift SQLite│    │  - Auth (bcrypt/JWT)  │  │
│  │ - Location GPS│    │  - Location (geofence)│  │
│  │ - WebSocket   │    │  - Points (gamify)    │  │
│  └──────────────┘    │  - System (admin)     │  │
│                      │  - Sync (deltas)      │  │
│                      │  - WoL (wake devices) │  │
│                      └───────┬───────────────┘  │
│                              │                   │
│                      ┌───────▼───────────────┐  │
│                      │  Sync Server (Go)     │  │
│                      │  Port :8080           │  │
│                      │                       │  │
│                      │  - Delta sync handler │  │
│                      │  - JSONL append log   │  │
│                      │  - task_capture events│  │
│                      │  - obsidian_note sync │  │
│                      └───────────────────────┘  │
└─────────────────────────────────────────────────┘
```

### Runtime Requirements:
- **Host Machine**: Windows or Linux PC running the Go host daemon
- **Mobile**: Android device with Flutter client APK
- **Network**: All devices must be on the same Tailscale tailnet
- **No Cloud**: Zero external cloud dependencies — fully self-hosted

## 6. Security Model

### Authentication:
- **bcrypt** password hashing (via `golang.org/x/crypto/bcrypt`)
- Passwords stored hashed in `data/users.json` — never plaintext
- **Token-based sessions**: Random 32-byte hex token generated on login
- Token sent as `Authorization: Bearer <token>` header on all requests
- Token validated server-side on `/api/v1/auth/validate`
- Auto-seeded `admin` user on first boot (password: `admin`) — should be changed immediately

### Authorization:
- **Role-based access control (RBAC)**: Three roles — `ADMIN`, `USER`, `CHILD`
- `CHILD` role intercepted at system settings endpoints → returns HTTP 403
- Points-based access gating for app launches

### Transport Encryption:
- **All traffic over WireGuard** via Tailscale tsnet — end-to-end encrypted
- No plaintext HTTP endpoints exposed publicly
- No port forwarding or public IPs needed

### Data Security:
- Local SQLite database (Drift) — no cloud database
- Preferences stored in local JSON files
- `tsnet-state/` contains WireGuard private keys — excluded from git
- Compiled binaries excluded from git

### Planned (from sprint):
- `EncryptedSharedPreferences` wrapper for Android credential storage (SEC-001, pending)

## 7. All Automation Triggers

### Geofence Automations (`location/automations.go`):
| Geofence Zone | Trigger | Action |
|---------------|---------|--------|
| "Work Polygon" | Enter | Start robot vacuum, activate work-mode lighting |
| "Home Base" | Enter | Turn on AC, activate home lighting |

### Points Automations (`points/router.go`):
| Condition | Action |
|-----------|--------|
| Balance goes negative after voucher redemption | **TV Lock Webhook** fires — restricts entertainment access |

### Notification Drip (`auth/router.go`):
- Template-based notification system
- New notification surfaces every 15 seconds
- Categories: System Updates, Habit Reminders, Security Logs, Financial Alerts, VM Manager, YouTube Client, Geofence Alerts

### Wake-on-LAN (`wol.go`):
- Send magic packet to any device by MAC address
- Used to remotely wake sleeping PCs on the network

## Additional Files

### `setup.ps1` (Development Bootstrap):
- Checks for and installs: **Git**, **Go**, **Flutter** via `winget`
- Runs `flutter pub get` in client directory
- Runs `go mod tidy` in backend directories
- Configures Flutter for Android and Windows platforms
- Requires PowerShell as Administrator

### Docker (`backend/Dockerfile.sync`):
```dockerfile
FROM golang:1.22-alpine
WORKDIR /app
COPY server/ .
RUN go build -o server .
EXPOSE 8080
CMD ["./server"]
```

### `docker-compose.yml`:
- Defines `sync-server` service from `Dockerfile.sync`
- Maps port `8080:8080`
- Mounts `./data` volume for persistent storage
