<p align="center">
  <h1 align="center">LifeOS</h1>
  <p align="center"><strong>Personal Digital Sovereignty Platform</strong></p>
  <p align="center">
    A self-hosted, offline-first operating system layer that consolidates your entire digital life into a single, private, unified workspace.
  </p>
  <p align="center">
    <img src="https://img.shields.io/badge/version-1.5.0-blue" alt="Version" />
    <img src="https://img.shields.io/badge/build-33-green" alt="Build" />
    <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter" />
    <img src="https://img.shields.io/badge/Go-1.26-00ADD8?logo=go" alt="Go" />
    <img src="https://img.shields.io/badge/license-private-lightgrey" alt="License" />
  </p>
</p>

---

## Web Access (Family Portal)

Access LifeOS from **any browser** (PC, tablet, phone — no installation needed):

- **Public URL (permanent):** `https://lifeos-host.husky-forel.ts.net`
  *(Tailscale Funnel — HTTPS, valid certificate, served by the host daemon itself)*
- **Login:** with your own LifeOS account (username/password), or **Google / GitHub** single sign-on (invite-only — the admin must create or map your account first).
- **Security:** every API call (except the public login/register/OAuth flows) requires a **JWT** issued by the daemon. Account **registration is disabled on the public internet path** — new accounts can only be created on your private network.
- All traffic is HTTPS end-to-end; the Flutter web portal is served by the daemon at `/`.

*If the daemon runs on a network that blocks Tailscale's control server, ask the admin — a temporary fallback URL may be provided.*

---

# For Users

## What is LifeOS?

LifeOS is your **personal command center** — a single app that replaces dozens of tools you use every day. Notes, calendar, finances, media, maps, home automation, and more — all in one place, running on **your devices**, with **your data never leaving your network**.

Think of it as a private operating system for your life.

### Core Principles

- ** You Own Your Data** — Everything stays on your devices. No cloud. No subscriptions. No tracking.
- ** Works Offline** — Every feature works without internet. Sync happens automatically when devices reconnect.
- ** Gamified Productivity** — Earn Star Points and RPG experience for completing tasks, habits, and learning. Spend them to unlock rewards.
- ** Family-Friendly** — Built-in parental controls (Child Lock), family leaderboards, and role-based access.

---

## Features

###  Home Screen
A custom lock screen with PIN / login / OAuth, real-time clock, and a live notifications feed color-coded by category (system, habits, security, finances). A connection status badge shows your current route (Tailscale Mesh / Local Wi-Fi / Remote Cloud).

###  Spatial Engine
Navigate the whole OS with the **keyboard**: arrow keys move across the module grid, double-bump at a screen edge to jump to the adjacent container, `Esc` steps back, double-`Esc` returns home. Every module is cached and transitioned with animated 350ms ease transitions.

###  Obsidian Zen Editor
A full **AppFlowy-powered markdown editor** integrated with your local vault:
- Wiki links `[[note]]` with vault autocomplete, tables, code blocks, callouts, toggles, headings 1–6, slash menu
- Markdown clipboard copy/paste **round-trip** (import and export)
- Entity embeds — insert a movie, book, music track, note, or geofence straight into a note
- File tree (drag & drop, rename, favorites), graph view, live collaboration presence (Yjs CRDT)
- Syncs to the daemon (DB-backed file system with LWW conflict resolution)

###  Music Library — "Audiophile Music Studio"
A high-fidelity private music player with a **Poweramp v3-style interface**:
- 10-band **DSP equalizer** (preamp, bass/treble boost, spatial audio) — native on Android, audio filters on Windows
- Smart mixes & playlists, waveform seekbar, synced lyrics (LRCLIB)
- Search, download and **stream from YouTube** via the daemon (yt-dlp + m4a proxy with caching, CORS and byte-range support)
- Scans local phone audio, plays through `just_audio` + `media_kit`, mini-player dock with "Audiophile Quality Tag"

###  Movie Library
- TMDB metadata enrichment (posters, genres, ratings), browse/search with filters
- Status tracking (Available / Downloading / Watched), watchlist, personal reviews
- VLC-based player with subtitle support

###  Photo & Video Gallery
A **1:1 Aves Libre replica** — full-screen viewer, video scrubber, map view with clustering, albums, cloud gallery, backup activity panel, peer-to-peer sharing (port 4444), and a **smart picker** that dedupes by content hash and perceptual (dHash) similarity.

###  Books
EPUB / CBZ / e-ink readers, audiobook player, highlights, and an **AI panel** (describe / summarize / chat) powered by your local LLM (default: Llama 3.2 via Ollama). Search across Gutenberg, OpenLibrary, MangaDex and Anna's Archive with background downloads.

###  RPG Player System
Family members level up like a game: XP from tasks and habits, attributes, quests (daily, main-line, pool), **illness/injury system** with recovery, and XP decay when you slack off. Star Points (points/100) power the voucher shop and app-launch gating.

###  Banking & Accounting
Banking dashboard with ledger, bill-pay tracker, budgets and **PDF statement import**. Accounting keeps government credentials and secure documents **AES-GCM encrypted** behind a PIN curtain.

###  And everything else
Maps & live tracking (OSM, geofences, radar, navigation overlay), flashcards (SM-2 spaced repetition), knowledge base with relationship graph, YouTube client (NewPipe bridge, point-costed sessions), virtual machine management, smart home control, dark-web / torrent monitor with quarantine, project infinity (word of the day + trivia), cloud backups, calendar/habits/tasks with voice capture — all wired into one grid.

---

## All Modules

LifeOS is designed as a modular platform. Here's every module and its current status:

| Module | Status | Description |
|--------|--------|-------------|
| Home Screen | ✅ Active | Lock screen, clock, notifications |
| Spatial Engine | ✅ Active | Keyboard grid navigation, edge bumping, Esc back-stack |
| Obsidian Zen Editor | ✅ Active | AppFlowy markdown editor, wiki links, tables, embeds, collab |
| Music Library | ✅ Active | Audiophile Studio, DSP EQ, smart playlists, m4a streaming |
| Movie Library | ✅ Active | TMDB metadata, watchlist, reviews, VLC player |
| Photo/Video Gallery | ✅ Active | Aves replica, smart picker, map clustering, P2P share |
| Book Library | ✅ Active | EPUB/CBZ/e-ink, audiobooks, AI panel, 4 sources |
| YouTube Client | ✅ Active | NewPipe bridge, point-costed sessions, downloads |
| Point Star System | ✅ Active | Gamification, leaderboard, vouchers, app gating |
| RPG Player System | ✅ Active | XP, leveling, quests, illness/injury, decay |
| Maps & Live Tracking | ✅ Active | GPS, geofences, radar, offline tiles, navigation |
| Calendar/Habits/Tasks | ✅ Active | CHTM hub, auto-scheduler, voice capture |
| Flashcards | ✅ Active | SM-2 spaced repetition, Anki import |
| Knowledge Base | ✅ Active | Topics, articles, relationship graph |
| Banking System | ✅ Active | Accounts, ledger, bills, budgets, PDF import |
| Accounting | ✅ Active | AES-GCM vault, PIN curtain, credentials |
| Home Management | ✅ Active | Smart devices, sensor logs, schedules |
| Virtual Machine Management | ✅ Active | VM list/toggle, remote file explorer, WoL |
| Dark Web Management | ✅ Active | Torrents monitor, quarantine, antivirus scan |
| Project Infinity | ✅ Active | Word of the day, trivia timeline |
| Cloud & Fake VM | 🔶 Partial | Backups + quarantine live; web-os/sandbox stubs |
| Preferences & Settings | ✅ Active | Profile, admin, grid configurator, matrix editor |
| Web Portal | ✅ Active | Flutter web served by daemon, Tailscale Funnel |

---

## Installation

### Download a Release

Go to [Releases](../../releases) and download:
- **Android**: `app-release.apk` — Install directly on your phone
- **Windows**: `lifeos-windows-release.zip` — Extract and run
- **Web**: served live at `https://lifeos-host.husky-forel.ts.net` — no install needed

### First Launch

1. Install the APK or extract the Windows build
2. On first launch, enter your **server URL** (your host machine's Tailscale IP + port 50051) — or let the app auto-discover it (mDNS, localhost, Tailscale mesh, emulator)
3. Register or log in with your credentials
4. The default admin account is `panospds` / `1897` — **change the password immediately**

---

## Running the Services

LifeOS requires two backend services running on your host machine:

### 1. Host Daemon (required)
The main backend service: auth (JWT + OAuth SSO), all domain APIs, web portal, maps, points, RPG, media streaming, and more:
```bash
cd backend/host-daemon
go run main.go
```
Listens on port `:50051` over your Tailscale mesh network (and `:50052` as the public Funnel upstream).

> **First run**: A browser will open for Tailscale authentication. Log in to your Tailscale account to register this node.

### 2. Sync Relay (optional)
Lightweight service for delta-based sync and Yjs collaboration relay:
```bash
cd server
go run main.go
```
Runs on port `:8080` (`POST /api/sync` → JSONL append log; `GET /ws` → Yjs room relay).

### 3. Flutter Client (for development)
```bash
cd client
flutter run
```

### 4. Web Portal (deploy)
```powershell
.\deploy_server.ps1          # build web + cross-compile Linux binaries + deploy via Tailscale SSH
.\client\deploy.ps1          # web-only deploy
```

---

## Network Setup

LifeOS uses [Tailscale](https://tailscale.com) to create a private encrypted mesh network between your devices. This means:
- ✅ No port forwarding needed
- ✅ No public IP addresses exposed
- ✅ Works across WiFi, cellular, and different networks
- ✅ All traffic encrypted with WireGuard
- ✅ Automatic peer discovery and reconnection
- ✅ Optional **Tailscale Funnel** for a public HTTPS web portal (invite-only accounts)

### Steps:
1. Create a free [Tailscale account](https://tailscale.com)
2. Install Tailscale on your Android phone
3. Run the Host Daemon — it embeds Tailscale automatically
4. All devices on the same Tailscale account can now reach each other
5. To publish the web portal publicly, run `tailscale funnel 443` on the host (the daemon configures this automatically when enabled)

---

# Technical Reference

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                    Tailscale Mesh Network                          │
│                    (WireGuard E2E Encrypted)                       │
│                                                                    │
│   ┌──────────────────┐   ┌────────────────────────────────────┐   │
│   │  Flutter Client   │   │  Host Daemon (Go)  :50051         │   │
│   │  Android/Windows/ │──►│  ─────────────────────────────────│   │
│   │  Web (Flutter)    │◄──┤  • Global JWT auth gate + OAuth   │   │
│   │                   │   │    SSO (GitHub/Google)            │   │
│   │  • ~32 modules    │   │  • ~38 domain packages            │   │
│   │  • Drift 60 tables│   │  • Per-module SQLite DBs (data/)  │   │
│   │  • Spatial engine │   │  • Web portal at / (Flutter web)  │   │
│   │  • JWT session    │   │  • Music m4a proxy + caching      │   │
│   │  • Offline queue  │   │  • Events WebSocket bus           │   │
│   └──────────────────┘   │  • RPG/points/automations engine   │   │
│                          └──────────────┬─────────────────────┘   │
│                                         │                         │
│                            ┌────────────▼──────────────────────┐  │
│                            │  Tailscale Funnel  :443 → :50052  │  │
│                            │  https://lifeos-host.husky-forel  │  │
│                            │  .ts.net (public, invite-only)    │  │
│                            └────────────┬──────────────────────┘  │
│                                         │                         │
│                            ┌────────────▼──────────────────────┐  │
│                            │  Sync Relay (Go)  :8080           │  │
│                            │  • POST /api/sync → JSONL log     │  │
│                            │  • GET /ws  Yjs collab relay +    │  │
│                            │    per-room ACL                   │  │
│                            └───────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

## Monorepo Structure

```
LifeOS/
├── client/                          # Flutter app (Android + Windows + Web)
│   ├── lib/
│   │   ├── main.dart                # Entry point, auth flow, notification polling
│   │   ├── app_module_router.dart   # ~32 module IDs → widgets
│   │   ├── auth_service.dart        # JWT login/logout/session/OAuth (web)
│   │   ├── api_client.dart          # HTTP client with auth headers + offline queue
│   │   ├── spatial_engine_scaffold.dart  # Keyboard grid navigation
│   │   ├── core/
│   │   │   ├── feature_registry.dart    # Module catalog (15 modules)
│   │   │   ├── domain_repositories.dart # Music/movies/books… daemon repos
│   │   │   ├── audio_dsp_service.dart   # 10-band DSP equalizer
│   │   │   ├── obsidian/                # Vault scanner, frontmatter, Yrs bindings
│   │   │   └── event_hub.dart           # WebSocket events bus client
│   │   ├── database/
│   │   │   ├── database.dart        # 60 Drift/SQLite tables (WAL)
│   │   │   └── schema/              # 9 schema files (core, chtm, economy, …)
│   │   ├── appflowy/                # Vendored AppFlowy editor fork + custom blocks
│   │   ├── plugins/                 # gallery, live_sharing, map_view, markdown, settings
│   │   ├── presentation/widgets/    # media_hub, finance, rpg_hub, knowledge_hub,
│   │   │                            #   chtm, zen_workspace, maps, points, …
│   │   └── theme/everforest_colors.dart  # Everforest design system
│   ├── web/                         # Flutter web (sqlite3.wasm + drift worker)
│   └── pubspec.yaml
│
├── backend/host-daemon/             # Go backend service (the single API)
│   ├── main.go                      # Entry: DB init, routes, auth gate, web portal
│   ├── tailnet.go                   # tsnet mesh + Tailscale Funnel (443 → :50052)
│   ├── ddns.go / wol.go / hyperv.go # Host utilities
│   ├── web/                         # Flutter web portal bundle (served at /)
│   └── internal/                    # ~38 domain packages:
│       ├── auth/ oauth/             # JWT gate, bcrypt, GitHub/Google SSO
│       ├── movies/ music/ books/ gallery/ notes/ media/
│       ├── player/ points/          # RPG + gamification
│       ├── banking/ accounting/ home/ infinity/ knowledge/ flashcards/
│       ├── zen/ engine/ markdown/   # Editor FS, entities, collab
│       ├── location/ events/ bus/ telemetry/ automations/
│       ├── vm/ youtube/ darkweb/ cloud/ sandbox/ kb/ chtm/ illness/ calendar/
│       ├── system/ backup/ sync/ voice/ devsim/
│       └── middleware/jwt.go        # Global auth gate
│
├── server/                          # Lightweight sync relay (:8080)
│   └── main.go, sync_hub.go, database.go   # JSONL sync + Yjs relay + ACL
│
├── native_yrs/                      # Rust Yrs CRDT C-ABI crate (libnative_yrs)
├── docs/                            # Zen editor architecture + markdown reference
├── vault/                           # Obsidian documentation vault
│   ├── 00 - System/                 # Workspace map of content
│   ├── 01 - Tiles/                  # 20 module specifications (all live)
│   ├── 02 - Technical Specs/        # Planning docs per module (annotated)
│   ├── 03 - work/                   # Architecture, trace logs, sprint tracking
│   └── 04 - LifeOS DevDocs/         # Security, sync, deployment, data schemas…
│
├── .agent/                          # AI agent config, version.json, workflows
├── .github/workflows/release.yml    # CI/CD: APK + Windows + release on v* tag
├── setup.ps1                        # Dev environment bootstrapper
├── deploy_server.ps1                # Web + daemon deploy to Linux box (Tailscale SSH)
└── README.md                        # This file
```

## Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Client** | Flutter 3.x / Dart | Cross-platform UI (Android, Windows, Web) |
| **Editor** | AppFlowy (vendored fork) | Markdown/rich-text editing with custom blocks |
| **Backend** | Go 1.26 | Host daemon, single API for all domains |
| **Database** | Drift (SQLite, WAL) | 60 local-first tables on device |
| **Server DBs** | SQLite per module | `data/` — one `.db` per domain |
| **Networking** | Tailscale tsnet | Embedded WireGuard mesh + Funnel |
| **Real-time** | gorilla/websocket | Events bus, radar live feed, Yjs collab relay |
| **Auth** | JWT (HS256) + bcrypt + OAuth | Sessions, roles, GitHub/Google SSO |
| **Maps** | flutter_map + OSM | Offline-capable map rendering |
| **Audio** | just_audio, media_kit, on_audio_query | Playback + local scanning + DSP EQ |
| **Video** | video_player, VLC | Movie/gallery playback |
| **RPG** | Custom Go engine | XP, leveling, quests, illness, decay |
| **AI** | LLM via Ollama (llama3.2 default) | Book summaries, app categorization |
| **CRDT** | Yrs (Rust, C ABI) | Collaborative editing state |
| **CI/CD** | GitHub Actions + Tailscale SSH | Automated releases + Linux deploys |

## API Reference

One daemon, one API: `/api/v1/<domain>`. Every domain endpoint supports `?q=` search.

### Auth (`/api/v1/auth/`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/login` | Authenticate → JWT + user profile |
| `POST` | `/register` | Create account (blocked on public Funnel path) |
| `GET` | `/me` | Validate JWT, return profile |
| `POST` | `/lock` | Lock current session |
| `GET` | `/users` | List users (admin) |
| `POST` | `/users` | Create user (username, password, role) |
| `PUT` | `/profile` | Update display name, status, avatar |
| `PUT` | `/password` | Change password |
| `GET` | `/notifications` | Poll time-dripped notifications |

### OAuth SSO (`/api/v1/oauth/`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/providers` | List enabled providers (GitHub/Google) |
| `GET` | `/start` | Redirect to provider (state-cookie CSRF) |
| `GET` | `/callback` | Exchange code → JWT → portal |

### Movies (`/api/v1/movies/`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/` | Browse/search (TMDB-enriched) |
| `PUT` | `/…` | Set status (available/downloading/watched) |
| `GET/POST` | `/watchlist` | Watchlist management |
| `GET/POST` | `/reviews` | Personal reviews |

### Music (`/api/v1/music/`) — public routes
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/tracks` | Library tracks |
| `GET` | `/search` | YouTube search (yt-dlp / NewPipe bridge) |
| `POST` | `/download` | Download to `data/media/music/` |
| `GET` | `/stream.m4a` | m4a proxy stream (cache + CORS + byte-range) |
| `GET` | `/ytstream/resolve` | Resolve stream URL + cache status |
| `GET` | `/lyrics` | LRCLIB synced lyrics |

### Books (`/api/v1/books/`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/` + `/search` | Browse / multi-source search |
| `POST` | `/download` + `/downloads` | Background download jobs |
| `PUT` | `/progress`, `/highlight` | Reading progress, highlights |
| `POST` | `/ai/describe`, `/ai/summarize`, `/ai/chat` | Local LLM features |

### Gallery (`/api/v1/gallery/`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/assets` | Asset list (hash/dHash metadata) |
| `GET` | `/asset?id=` | Asset detail / stream |

### RPG & Points (`/api/v1/player/`, `/api/v1/points/`, `/api/v1/rpg/`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/player/stats` | XP, attributes, level |
| `POST` | `/player/task/complete` | Task → XP + points pipeline |
| `GET` | `/rpg/quests` (+ add/activate/accept/complete/cancel/delete/update/add-main) | Quest workflow |
| `GET` | `/points/balance`, `/ledger`, `/leaderboard`, `/store` | Gamification data |
| `POST` | `/points/vouchers/redeem`, `/apps/deduct` | Spend points |

### Zen Editor (`/api/v1/zen/`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/sync` | LWW sync with tombstones |
| `GET` | `/fs/list`, `/fs/read` | Vault file tree |
| `POST` | `/fs/write`, `/fs/mkdir`, `/fs/delete`, `/fs/rename`, `/fs/copy` | File operations |

### Notes / Media / Knowledge
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/v1/notes` | Vault note search (path-traversal guarded) |
| `GET` | `/api/media/` | Media file serving |
| `GET` | `/api/v1/knowledge/categories`, `/articles` | Knowledge base |
| `GET` | `/api/v1/flashcards/decks` (+ create/import-anki/scan) | Flashcards |
| `GET` | `/api/v1/infinity/daily` | Word of the day + trivia |

### Banking / Home / VM / YouTube
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/v1/banking/parse-pdf` | PDF statement import |
| `GET` | `/api/v1/home/devices`, `POST` `/toggle`, `POST` `/sensors/report` | Smart home |
| `GET` | `/api/v1/vm` (+ toggle/discovery/explore) | Virtual machines |
| `GET` | `/api/v1/youtube/search`, `/streams` (+ sessions/start/stop) | YouTube client |
| `GET` | `/api/v1/darkweb/torrents` (+ promote) | Torrent monitor |

### System & Infrastructure
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET/POST` | `/api/v1/system/settings` | Settings (CHILD role blocked) |
| `POST` | `/api/v1/system/apps/categorize` | AI app categorization |
| `GET/POST` | `/api/v1/backup/…` | list/upload/download/chunk/merge |
| `POST` | `/api/v1/wol` | Wake-on-LAN magic packet |
| `POST` | `/api/v1/voice-parse` | Voice capture transcription |
| `POST` | `/api/v1/sync/push` | Delta sync envelope (base64+gzip) |
| `GET` | `/api/update/download` | OTA APK download |
| `GET` | `/api/health` | Health check |

### WebSockets
| Endpoint | Description |
|----------|-------------|
| `/api/v1/events?token=` | Global events bus (points, movies watched, …) |
| `/api/v1/radar/live?device_id=` | Real-time location broadcast |
| `/api/markdown/collab?doc_id=` | Per-document collab hubs (JWT-validated) |
| `/ws?token=` (:8080 relay) | Yjs room relay with per-room ACL |

**Total: 85+ endpoints** across ~38 domain packages on the single daemon.

## Database

- **Client (source of truth):** 60 Drift/SQLite tables (WAL) across 9 schema files — every table carries the sync quartet `updatedAt / syncedAt / isDirty / id`, with a buffered offline queue flushed every 15s.
- **Daemon:** one SQLite `.db` per module in `data/` (gallery, movies, books, finance, rpg, knowledge, flashcards, media, home, infinity, backup, darkweb, vm, voice, youtube, system, sync, engine, sandbox, devsim, zen…) plus JSON stores (`calendar.json`, `geofences.json`, `points.json`, `ledger.json`, `illness.json`).
- **Design rule (reference, don't copy):** entities stored once and referenced (`movie:imdb_id`, `book:isbn`, `photo:sha256`); uploads dedupe by content hash.

## Security Model

| Layer | Implementation |
|-------|---------------|
| **Transport** | WireGuard via Tailscale — all traffic E2E encrypted |
| **API Gate** | Global JWT middleware; explicit public allowlist only |
| **Authentication** | bcrypt passwords, JWT HS256 (24h), OAuth SSO (GitHub/Google) with CSRF state cookies |
| **Authorization** | RBAC: `ADMIN`, `USER`, `CHILD` (+ Child Lock on settings) |
| **Public Exposure** | Funnel serves only the portal; register/login denied publicly (invite-only) |
| **Storage** | Local SQLite only — no cloud database |
| **Credentials** | Hashed in DB; external API keys env-only, backend-only (never in client) |
| **Secrets** | `data/`, binaries, state dirs, `.env` files all gitignored |
| **Web Hardening** | No-cache headers, purged service worker, MD5-verified deploys |
| **Brute Force** | Per-IP login limiter (5 fails / 5 min) |

> **Default admin**: `panospds` / `1897` — change immediately on first boot.

## Automation Triggers

| Trigger | Condition | Action |
|---------|-----------|--------|
| Geofence Enter | GPS enters a zone | Webhook fires (smart home actions) |
| Points Negative Balance | Voucher redemption drops below 0 | TV Lock webhook |
| Task Completion | `player/task/complete` | +15 XP task / +10 habit, level-up, points |
| Engine Rules | `engine:upsert:<type>` facts | Rewards (zen log +20) + notifications |
| Events Bus | Any domain fact | Pushed live to all clients over WS |
| Wake-on-LAN | Manual API call | Magic packet to wake sleeping PC |

## CI/CD Pipeline

Automated on every `v*` tag push (`release.yml`):

```
git tag v33 → git push --tags
       │
       ▼
┌──────────────────┐   ┌──────────────────┐
│  Build Android   │   │  Build Windows   │
│  (ubuntu-latest) │   │ (windows-latest) │
│  Java 17 + Flutter│   │  Flutter stable  │
│  → APK (arm64)   │   │  → ZIP (x64)    │
└────────┬─────────┘   └────────┬─────────┘
         │                      │
         ▼                      ▼
    ┌────────────────────────────────┐
    │    Publish GitHub Release      │
    │  • Notes from version.json     │
    │  • app-release.apk attached    │
    │  • lifeos-windows.zip attached │
    └────────────────────────────────┘
```

Production web/daemon deploys use `deploy_server.ps1` (build → cross-compile → `tailscale ssh` → systemd → MD5 verify) targeting `pds-laptop-old`.

## Development Setup

### Prerequisites
- **Git**, **Go 1.22+**, **Flutter 3.x** (stable channel)
- A [Tailscale](https://tailscale.com) account (free)
- Android Studio or VS Code with Flutter extension

### Quick Start (Windows)
```powershell
# Run the automated setup script (as Administrator)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
.\setup.ps1

# Start the host daemon
cd backend/host-daemon
go run main.go

# In a new terminal, start the sync relay
cd server
go run main.go

# In a new terminal, run the Flutter client
cd client
flutter run

# Web portal (deploy mode)
.\deploy_server.ps1 -SkipBuild   # just deploy, skip rebuild
```

### Build the Web Portal
```powershell
cd client
flutter build web --release
```

## External Dependencies

### Go (host daemon)
| Package | Version | Purpose |
|---------|---------|---------|
| `tailscale.com` | v1.82+ | Embedded Tailscale mesh + Funnel |
| `gorilla/websocket` | v1.5.3 | WebSocket server (events, radar, collab) |
| `golang.org/x/crypto` | latest | bcrypt password hashing |
| `golang-jwt/jwt` | latest | HS256 JWT issuance/validation |
| `mattn/go-sqlite3` | v1.14+ | Per-module SQLite |
| `yt-dlp` (binary) | latest | YouTube search/download/stream |

### Flutter (key packages)
| Package | Version | Purpose |
|---------|---------|---------|
| `appflowy_editor` | ^1.4.0 (vendored fork) | Zen Editor engine |
| `drift` | any | SQLite ORM, 60 tables |
| `just_audio` + `media_kit` | latest | Music playback engine |
| `on_audio_query` | ^2.9.0 | Local audio scanning |
| `flutter_map` | ^8.3.0 | OSM rendering |
| `photo_manager` | 3.9.0 | Gallery device scanning |
| `nsd` | ^5.0.1 | mDNS local discovery |
| `window_manager` / `desktop_multi_window` | latest | Desktop multi-window |
| `flutter_secure_storage` | latest | JWT persistence |
| `web_socket_channel` | ^3.0.3 | WS client |
| `yrs` (Rust) | 0.21 | CRDT collab state |

---

<p align="center">
  <sub>Built with privacy-first principles. No cloud. No tracking. Your data, your rules.</sub>
</p>