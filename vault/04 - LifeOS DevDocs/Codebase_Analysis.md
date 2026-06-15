# LifeOS Codebase Analysis & Architecture Report

This document contains a comprehensive analysis of the LifeOS codebase across the client, backend, and documentation vault, as analyzed on June 15, 2026.

---

## 1. Overall Vision & Philosophy

LifeOS is a **local-first, offline-first, multi-platform personal operating system**. It is designed to consolidate a user's entire digital life into a single, private, unified workspace.

*   **Digital Sovereignty**: You own all your data. Nothing leaves your devices unless explicitly allowed.
*   **Offline-First**: Functions without the internet; synchronizes opportunistically.
*   **Gamification**: The "Point Star System" gamifies productivity, rewarding beneficial actions and penalizing excessive leisure.
*   **Self-Hosted Infrastructure**: Runs via Tailscale mesh networking without cloud dependencies.
*   **Design**: Strict Everforest Minimalist Flat-Line theme across UIs.

---

## 2. Client Architecture (Flutter)

The client (`client/`) is built with Flutter (Android & Windows) and features a spatial UI engine.

### App Initialization (`main.dart`)
1.  Initializes `PreferencesService` (JSON storage).
2.  Initializes `AppDatabase` (Drift/SQLite).
3.  Restores Auth Session via `AuthService.restoreSession()`.
4.  Displays Login Screen or `AppShell` (spatial grid dashboard).
5.  Starts a background notification polling timer (`/api/v1/notifications`).
6.  Initializes `LocationTrackerPlugin` for background GPS streaming.

### Authentication Flow
*   **Login**: Sends credentials to `POST /api/v1/auth/login`. Returns a token and user profile, saved via `PreferencesService`.
*   **Restore**: Validates saved token via `GET /api/v1/auth/validate`.
*   **Logout**: Clears local token and preferences.

### Registered Modules (22 Total)
Key modules include: `home_screen`, `point_star_system`, `maps_live_tracking`, `preferences_setting`, `obsidian_zen_workspace`, `knowledge_base`, `calendar_habit_task`, `cloud_vm`, `vm_management`, `live_sharing`, and `location_tracker`.

### Local Database (Drift - 27 Tables)
Includes tables for productivity (`tasks`, `habits`), media (`movies`, `music_tracks`), location (`maps_location_history`, `maps_geofences`), points (`point_star_balances`, `point_star_ledger`), and synchronization (`sync_deltas`, `sync_state`).

### UI & Widgets
*   **Lock Screen**: Custom swipe-up gesture, animated login form.
*   **Maps Dashboard**: Live location feed, OSM map rendering, geofence drawing, radar visualization.
*   **Point Star System**: Family leaderboard, transaction ledger, voucher redemption, and point-gated module wrappers.
*   **Android Launcher**: Flat grid/folder views, AI-powered app categorization, point-gated app launching.
*   **Preferences**: Profile editing, admin console (user management), Tailscale node monitoring.

---

## 3. Backend Infrastructure (Go Host Daemon)

The host daemon (`backend/host-daemon/`) serves as the core infrastructure and API layer.

### API Endpoints (Port 50051)
*   **Auth (`/api/v1/auth/`)**: Login, lock, user management (CRUD), profile updates, token validation. Uses bcrypt hashing and JSON-based persistence (`data/users.json`).
*   **Location (`/api/v1/radar/`)**: Geofence management, GPS reporting, WebSocket live feed (`/live`), routing.
*   **Points (`/api/v1/points/`)**: Leaderboard, ledger history, voucher redemption (with TV Lock triggers).
*   **System (`/api/v1/system/`)**: Health status, settings (Role-Based Access Control), Tailscale node status, reboot/shutdown commands, OS service listing, AI app categorization.
*   **Sync (`/api/v1/sync/`)**: Delta change record submission.
*   **Infrastructure (`/api/v1/wol`)**: Wake-on-LAN functionality.

### Networking & Security
*   **Embedded Tailscale (`tsnet`)**: The daemon embeds Tailscale, meaning it acts as its own node (`lifeos-host`) without requiring a separate Tailscale client. All traffic on port 50051 is WireGuard-encrypted over the mesh.
*   **Authentication**: Token-based (Bearer).
*   **Authorization**: RBAC (ADMIN, USER, CHILD).
*   **Geofence Automations**: Entering specific zones triggers actions like starting a robot vacuum, adjusting lights, or turning on the AC.

---

## 4. Synchronization Protocol

LifeOS uses a delta-based transactional sync mechanism.

1.  **Deltas**: Changes in the local database generate delta records via a Drift change interceptor.
2.  **Queue**: Deltas are queued locally (offline support).
3.  **Transport**: Polled and sent to the sync server (`POST /api/v1/sync`).
4.  **Resolution**: Employs Last-Write-Wins (LWW) with millisecond timestamps for relational data. Markdown files currently use direct overwrite.

---

## 5. Deployment & CI/CD

*   **GitHub Actions (`release.yml`)**: Triggered by `v*` tags.
*   **Builds**: Compiles the Android APK and Windows executable.
*   **Release**: Generates release notes and publishes artifacts to GitHub Releases.
*   **Setup Script (`setup.ps1`)**: Bootstraps the development environment, installing Go, Flutter, and dependencies automatically.

---

## 6. Point Star System Mechanics

*   **Earning**: Completing habits (+10), flashcards (+15), reading (+20), chores (+10). Deductions exist for negative habits or missed tasks.
*   **Spending (Vouchers)**: Screen time (50 pts), Movie Night (100 pts), Late Bedtime (200 pts).
*   **Gating**: External Android apps require points to launch.
*   **Penalties**: If a balance goes negative, webhooks lock entertainment access (e.g., smart TVs).

---

## 7. Current Project Status

**Active / Functional Components:**
*   Maps & Live Tracking (REST, WS, Flutter Dashboard)
*   Point Star Gamification (Leaderboard, Vouchers, Gating)
*   Authentication & User Management
*   Android App Launcher Mode
*   Core App UI & Widget System
*   Host Daemon & Sync Backend basics

**Pending / Future Sprints:**
*   `EncryptedSharedPreferences` for Android.
*   Full CRDT-based synchronization (currently LWW).
*   Zero-Trust Proxy (Web Fail-Safe Layer) integration.
*   Additional modules like Knowledge Base, Accounting, and Virtual Machine management UI.
