<p align="center">
  <h1 align="center">LifeOS</h1>
  <p align="center"><strong>Personal Digital Sovereignty Platform</strong></p>
  <p align="center">
    A self-hosted, offline-first operating system layer that consolidates your entire digital life into a single, private, unified workspace.
  </p>
  <p align="center">
    <img src="https://img.shields.io/badge/version-1.0.2-blue" alt="Version" />
    <img src="https://img.shields.io/badge/build-27-green" alt="Build" />
    <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter" />
    <img src="https://img.shields.io/badge/Go-1.22-00ADD8?logo=go" alt="Go" />
    <img src="https://img.shields.io/badge/license-private-lightgrey" alt="License" />
  </p>
</p>

---

# For Users

## What is LifeOS?

LifeOS is your **personal command center** — a single app that replaces dozens of tools you use every day. Notes, calendar, finances, media, maps, home automation, and more — all in one place, running on **your devices**, with **your data never leaving your network**.

Think of it as a private operating system for your life.

### Core Principles

- ** You Own Your Data** — Everything stays on your devices. No cloud. No subscriptions. No tracking.
- ** Works Offline** — Every feature works without internet. Sync happens automatically when devices reconnect.
- ** Gamified Productivity** — Earn Star Points for completing tasks, habits, and learning. Spend them to unlock rewards.
- ** Family-Friendly** — Built-in parental controls, family leaderboards, and role-based access.

---

## Features

###  Home Screen
A custom lock screen with swipe-to-unlock, real-time clock, and a live notifications feed color-coded by category (system, habits, security, finances).

###  Point Star System
A household gamification engine where family members earn points through productive activities:

| Earn Points | Spend Points |
|-------------|-------------|
| Complete daily habits (+10) | 30min Screen Time (50 pts) |
| Finish a flashcard session (+15) | Movie Night (100 pts) |
| Read for 30 minutes (+20) | Game Session (150 pts) |
| Complete a task (+5 to +25) | Late Bedtime (200 pts) |
| Exercise logged (+15) | Choose Dinner (300 pts) |
| Chore completed (+10) | Day Off Chores (500 pts) |

Features a **family leaderboard** with gold/silver/bronze rankings, a **voucher rewards shop**, and **point-gated app access** — each app launch can cost Star Points.

###  Maps & Live Tracking
Real-time GPS tracking with OpenStreetMap, live location feed via WebSocket, interactive geofence zone drawing, and turn-by-turn navigation overlay. Includes an animated dark radar sweep visualization.

###  Android Launcher Mode
A full Android home screen replacement with an app drawer, dock bar, and AI-powered app categorization (powered by Gemini). Apps are organized into folders and each launch can be gated behind Star Points.

###  Obsidian Zen Editor
A built-in markdown editor integrated with your local vault. Read, edit, and link notes with frontmatter support and automatic link tokenization.

###  Preferences & Settings
System settings hub with:
- **My Profile** — Edit display name, status, and avatar
- **Admin Console** — Create and manage family user accounts
- **Grid Configurator** — Customize your dashboard layout
- **Tailscale Node Monitor** — View all devices on your mesh network

###  Authentication
Secure login with username/password, bcrypt-hashed credentials, "Remember Me" session persistence, and role-based access control (Admin, User, Child).

###  Remote System Management
Control your host machine from anywhere on your network — reboot, shutdown, view services, stream logs, and run diagnostics.

---

## All Modules

LifeOS is designed as a modular platform. Here's every module and its current status:

| Module | Status | Description |
|--------|--------|-------------|
| Home Screen | ✅ Active | Lock screen, clock, notifications |
| Point Star System | ✅ Active | Gamification, leaderboard, vouchers |
| Maps & Live Tracking | ✅ Active | GPS, geofences, live radar |
| Preferences & Settings | ✅ Active | Profile, admin, grid config |
| Obsidian Zen Editor | ✅ Active | Markdown vault editor |
| Live Sharing | ✅ Active | WebSocket real-time sharing |
| Location Tracker | ✅ Active | Background GPS plugin |
| Knowledge Base | 🔜 Planned | PKM wiki with backlinks |
| Calendar & Habits | 🔜 Planned | Unified calendar + habits + tasks |
| Flashcards | 🔜 Planned | Spaced repetition system |
| Accounting | 🔜 Planned | Personal finance tracking |
| Banking System | 🔜 Planned | Bank account aggregation |
| Book Library | 🔜 Planned | EPUB/PDF reader |
| Movie Library | 🔜 Planned | Collection and watchlist |
| Music Library | 🔜 Planned | Local music player |
| Photo/Video Gallery | 🔜 Planned | Local media gallery |
| YouTube Client | 🔜 Planned | Privacy-focused viewer |
| Cloud & Fake VM | 🔜 Planned | Sandboxed VM execution |
| VM Management | 🔜 Planned | Hyper-V/Docker control |
| Dark Web Management | 🔜 Planned | Tor/I2P gateway |
| Home Management | 🔜 Planned | IoT/smart home control |
| Project Infinity | 🔜 Planned | Project management |

---

## Installation

### Download a Release

Go to [Releases](../../releases) and download:
- **Android**: `app-release.apk` — Install directly on your phone
- **Windows**: `lifeos-windows-release.zip` — Extract and run

### First Launch

1. Install the APK or extract the Windows build
2. On first launch, enter your **server URL** (your host machine's Tailscale IP + port 50051)
3. Register or log in with your credentials
4. The default admin account is `admin` / `admin` — **change the password immediately**

---

## Running the Services

LifeOS requires two backend services running on your host machine:

### 1. Host Daemon (required)
The main backend service handling auth, points, maps, system management, and more:
```bash
cd backend/host-daemon
go run main.go
```
Runs on port `:50051` over your Tailscale mesh network.

> **First run**: A browser will open for Tailscale authentication. Log in to your Tailscale account to register this node.

### 2. Sync Server (optional)
Lightweight service for delta-based data synchronization between devices:
```bash
cd server
go run main.go
```
Runs on port `:8080`.

### 3. Flutter Client (for development)
```bash
cd client
flutter run
```

---

## Network Setup

LifeOS uses [Tailscale](https://tailscale.com) to create a private encrypted mesh network between your devices. This means:
- ✅ No port forwarding needed
- ✅ No public IP addresses exposed
- ✅ Works across WiFi, cellular, and different networks
- ✅ All traffic encrypted with WireGuard
- ✅ Automatic peer discovery and reconnection

### Steps:
1. Create a free [Tailscale account](https://tailscale.com)
2. Install Tailscale on your Android phone
3. Run the Host Daemon — it embeds Tailscale automatically
4. All devices on the same Tailscale account can now reach each other

---

---

# Technical Reference

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                  Tailscale Mesh Network                  │
│                  (WireGuard E2E Encrypted)               │
│                                                         │
│  ┌────────────────┐         ┌─────────────────────────┐ │
│  │ Flutter Client  │         │  Host Daemon (Go)       │ │
│  │ Android/Windows │◄───────►│  :50051 via tsnet       │ │
│  │                 │   REST  │                         │ │
│  │ • 22 Modules    │   + WS  │  • Auth (bcrypt/token)  │ │
│  │ • 27 DB Tables  │         │  • Location (geofence)  │ │
│  │ • 6 Plugins     │         │  • Points (gamify)      │ │
│  │ • Drift SQLite  │         │  • System (admin)       │ │
│  │ • Auth Service  │         │  • Sync (deltas)        │ │
│  └────────────────┘         │  • WoL (wake devices)   │ │
│                              └──────────┬──────────────┘ │
│                                         │                │
│                              ┌──────────▼──────────────┐ │
│                              │  Sync Server (Go)       │ │
│                              │  :8080                  │ │
│                              │                         │ │
│                              │  • Delta sync handler   │ │
│                              │  • JSONL append log     │ │
│                              │  • Event type routing   │ │
│                              └─────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## Monorepo Structure

```
LifeOS/
├── client/                          # Flutter app (Android + Windows)
│   ├── lib/
│   │   ├── main.dart                # Entry point, auth flow, notification polling
│   │   ├── app_shell.dart           # Root layout, spatial grid
│   │   ├── auth_service.dart        # Login/logout/session management
│   │   ├── api_client.dart          # HTTP client with auth headers
│   │   ├── core/
│   │   │   └── feature_registry.dart  # 22 registered module definitions
│   │   ├── database/
│   │   │   ├── database.dart        # 27 Drift/SQLite tables
│   │   │   ├── maps_dao.dart        # Location data queries
│   │   │   └── preferences_service.dart  # JSON-based reactive preferences
│   │   ├── plugins/
│   │   │   ├── location_tracker/    # Background GPS streaming
│   │   │   ├── live_sharing/        # WebSocket real-time sharing
│   │   │   ├── gallery/             # Photo/video indexing
│   │   │   ├── map_view/            # OSM tile abstraction
│   │   │   ├── markdown/            # Vault file parser
│   │   │   └── settings/            # Platform settings integration
│   │   └── presentation/widgets/
│   │       ├── home_screen/         # Clock, lock screen, notifications
│   │       ├── maps_live_tracking/  # 9 widgets: map, radar, geofence, nav
│   │       ├── point_star_system/   # Dashboard, vouchers, gating, leaderboard
│   │       └── preferences_setting/ # Profile, admin, launcher, grid, nodes
│   ├── android/                     # Android platform config
│   ├── windows/                     # Windows platform config
│   └── pubspec.yaml                 # Dependencies
│
├── backend/host-daemon/             # Go backend service
│   ├── main.go                      # Entry point, tsnet init, 24 routes
│   ├── wol.go                       # Wake-on-LAN utility
│   └── internal/
│       ├── auth/
│       │   ├── router.go            # Login, register, validate, notifications
│       │   └── users.go             # bcrypt hashing, JSON user store
│       ├── location/
│       │   ├── router.go            # Geofence CRUD, location reporting, routing
│       │   ├── geofence.go          # Haversine + ray-casting proximity engine
│       │   ├── websocket.go         # Real-time location broadcast broker
│       │   └── automations.go       # Geofence-triggered smart home actions
│       ├── points/
│       │   └── router.go            # Leaderboard, ledger, voucher redemption
│       ├── system/
│       │   └── router.go            # Reboot, shutdown, services, logs, AI categorize
│       └── sync/
│           └── router.go            # Delta sync ingestion
│
├── server/                          # Lightweight sync server
│   └── main.go                      # Delta handler, JSONL append log
│
├── vault/                           # Obsidian documentation vault
│   ├── 00 - System/                 # Project home page
│   ├── 01 - Tiles/                  # Module specifications (20+ tiles)
│   ├── 02 - Technical Specs/        # Point Star System, Accounting specs
│   ├── 03 - work/                   # Sprint tasks, architecture, trace logs
│   └── 04 - LifeOS DevDocs/        # Architecture docs, schemas, protocols
│
├── .agent/                          # AI agent configuration
│   ├── version.json                 # Build number tracking
│   ├── subagent_delegation.md       # Agent role definitions
│   ├── rules/                       # 8 scope-specific rules
│   └── workflows/                   # 8 workflow definitions
│
├── .github/workflows/
│   └── release.yml                  # CI/CD: build APK + Windows + publish release
│
├── setup.ps1                        # Dev environment bootstrapper
└── README.md                        # This file
```

## Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Client** | Flutter 3.x / Dart | Cross-platform UI (Android + Windows) |
| **Backend** | Go 1.22 | Host daemon, API server |
| **Database** | Drift (SQLite) | 27 local-first tables |
| **Networking** | Tailscale tsnet | Embedded WireGuard mesh |
| **Real-time** | gorilla/websocket | Live location + data streaming |
| **Auth** | bcrypt + Bearer tokens | Password hashing + session management |
| **Maps** | flutter_map + OSM | Offline-capable map rendering |
| **GPS** | geolocator | Battery-optimized background tracking |
| **AI** | Google Gemini API | App categorization (with local fallback) |
| **CI/CD** | GitHub Actions | Automated APK + Windows builds on tag push |
| **Containerization** | Docker | Optional sync server deployment |

## API Reference

### Auth (`/api/v1/auth/`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/login` | Authenticate → returns token + user profile |
| `POST` | `/lock` | Lock current session |
| `GET` | `/users` | List all users |
| `POST` | `/users` | Create user (username, password, role) |
| `PUT` | `/profile` | Update display name, status, avatar |
| `GET` | `/validate` | Validate Bearer token |
| `GET` | `/notifications` | Poll time-dripped notifications |

### Location (`/api/v1/radar/`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/geofences` | List geofence zones |
| `POST` | `/geofences` | Create geofence (circle or polygon) |
| `POST` | `/report` | Submit GPS location → triggers automations |
| `GET` | `/live` | WebSocket upgrade → real-time broadcast |
| `POST` | `/routing` | Request route between coordinates |

### Points (`/api/v1/points/`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/leaderboard` | Family rankings by total points |
| `GET` | `/ledger` | Transaction history |
| `POST` | `/vouchers/redeem` | Redeem voucher → deduct points |

### System (`/api/v1/system/`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/status` | Host health (CPU, RAM, uptime, OS) |
| `GET`/`POST` | `/settings` | System settings (blocked for CHILD role) |
| `GET` | `/nodes` | Tailscale mesh node status |
| `POST` | `/reboot` | Reboot host machine |
| `POST` | `/shutdown` | Shutdown host machine |
| `GET` | `/services` | List running OS services |
| `GET` | `/logs` | Stream system logs |
| `POST` | `/apps/categorize` | AI-powered app categorization |
| `GET` | `/diagnostics` | Go runtime stats |

### Sync (`/api/v1/sync/`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/` | Submit delta change records |

### Infrastructure
| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/v1/wol` | Wake-on-LAN magic packet |

**Total: 24 endpoints** across 5 modules.

## Database Schema

27 Drift/SQLite tables organized by module:

| Domain | Tables |
|--------|--------|
| **Core** | `obsidian_files`, `obsidian_links`, `sync_deltas`, `sync_state`, `local_notifications` |
| **Productivity** | `calendar_events`, `habits`, `tasks`, `flashcard_decks`, `flashcards`, `projects` |
| **Finance** | `accounting_transactions`, `banking_accounts` |
| **Media** | `books`, `movies`, `music_tracks`, `photos`, `videos`, `youtube_subscriptions` |
| **Infrastructure** | `cloud_vms`, `docker_containers`, `iot_devices`, `knowledge_entries` |
| **Gamification** | `point_star_balances`, `point_star_ledger` |
| **Location** | `maps_location_history`, `maps_geofences` |

## Security Model

| Layer | Implementation |
|-------|---------------|
| **Transport** | WireGuard encryption via Tailscale — all traffic E2E encrypted |
| **Authentication** | bcrypt password hashing, random 32-byte hex session tokens |
| **Authorization** | RBAC with 3 roles: `ADMIN`, `USER`, `CHILD` |
| **Storage** | Local SQLite only — no cloud database |
| **Credentials** | Hashed in `data/users.json`, tokens in memory |
| **Network** | No public endpoints — services only reachable within tailnet |
| **Git Security** | Binaries, state dirs, API keys, and `.env` files all gitignored |

> **Default admin**: `admin` / `admin` — change immediately on first boot.

## Automation Triggers

| Trigger | Condition | Action |
|---------|-----------|--------|
| Geofence Enter: "Home Base" | GPS enters home zone | Turn on AC + home lighting |
| Geofence Enter: "Work Polygon" | GPS enters work zone | Start robot vacuum + work lighting |
| Points: Negative Balance | Voucher redemption drops below 0 | TV Lock Webhook fires |
| Notification Drip | Every 15 seconds | New notification surfaces from template |
| Wake-on-LAN | Manual API call | Send magic packet to wake sleeping PC |

## CI/CD Pipeline

Automated on every `v*` tag push:

```
git tag v27 → git push --tags
       │
       ▼
┌──────────────────┐   ┌──────────────────┐
│  Build Android   │   │  Build Windows   │
│  (ubuntu-latest) │   │ (windows-latest) │
│                  │   │                  │
│  Java 17 + Flutter│   │  Flutter stable  │
│  → APK (arm64)   │   │  → ZIP (x64)    │
└────────┬─────────┘   └────────┬─────────┘
         │                      │
         ▼                      ▼
    ┌────────────────────────────────┐
    │    Publish GitHub Release      │
    │                                │
    │  • Release notes from template │
    │  • app-release.apk attached    │
    │  • lifeos-windows.zip attached │
    └────────────────────────────────┘
```

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

# In a new terminal, start the sync server
cd server
go run main.go

# In a new terminal, run the Flutter client
cd client
flutter run
```

### Docker (Sync Server Only)
```bash
docker-compose up -d
```

## External Dependencies

### Go (3 packages)
| Package | Version | Purpose |
|---------|---------|---------|
| `tailscale.com` | v1.82.5 | Embedded Tailscale mesh networking |
| `gorilla/websocket` | v1.5.3 | WebSocket server |
| `golang.org/x/crypto` | v0.38.0 | bcrypt password hashing |

### Flutter (10 packages)
| Package | Version | Purpose |
|---------|---------|---------|
| `drift` | any | SQLite ORM with code generation |
| `flutter_map` | ^8.3.0 | OpenStreetMap tile rendering |
| `geolocator` | ^14.0.3 | GPS location services |
| `web_socket_channel` | ^3.0.3 | WebSocket client |
| `http` | ^1.2.0 | HTTP client |
| `path_provider` | ^2.1.5 | File system paths |
| `url_launcher` | ^6.3.2 | Open URLs/apps |
| `installed_apps` | ^2.1.1 | List installed Android apps |
| `latlong2` | ^0.9.1 | Geographic coordinates |
| `desktop_multi_window` | ^0.2.0 | Desktop multi-window |
| `flutter_display_mode` | ^0.6.0 | High refresh rate |

---

<p align="center">
  <sub>Built with privacy-first principles. No cloud. No tracking. Your data, your rules.</sub>
</p>
