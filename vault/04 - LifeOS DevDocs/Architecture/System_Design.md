# System Design Blueprint

> [!NOTE]
> **Home:** [[04 - LifeOS DevDocs/Home|Home]] | **Related:** [[04 - LifeOS DevDocs/Architecture/Core_UI_Dashboard|Core UI Dashboard]] · [[04 - LifeOS DevDocs/INFRASTRUCTURE_CONTROL|Infrastructure Control]] · [[04 - LifeOS DevDocs/EMBEDDED_NETWORK|Embedded Network]] · [[04 - LifeOS DevDocs/DEPLOYMENT_CI_CD|Deployment CI/CD]] · [[03 - work/system_architecture|System Architecture (Work)]]


## 1. Core Architecture
LifeOS is a local-first, multi-platform personal system that leverages an active Obsidian Vault as its definitive source of truth.

### The Stack
*   **Desktop Client (Windows 11 Pro):** Flutter Native (C++) interacting with local system paths.
*   **Mobile Client (Android ARM64):** Flutter Native bridging to a Go-Mobile Tailscale backend.
*   **Local Caching:** Drift (Reactive SQLite C-bindings) for rapid UI hydration and query efficiency.
*   **Host Control Daemon:** A secure, Go-based background Windows service (`backend/host-daemon`) executing Hyper-V and Wake-on-LAN commands via PowerShell.

## 2. Vault-Centric Storage Model
The entire project revolves around the `vault/` directory. All development documentation, user manuals, and dynamic logs are stored as Markdown, ensuring maximum portability, offline capability, and immediate human readability.

## 3. Network Topology
*   **Zero-Exposure Mesh:** Applications communicate entirely via embedded Tailscale (`tsnet`) user-space nodes.
*   **Host API Endpoints:** The Host Daemon listens on internal port `:50051`.
## 4. Android Launcher & Gamification
*   **Operating System Replacement:** The Android build includes `android.intent.category.HOME`, making LifeOS capable of being the default launcher for the device.
*   **Global Lock Screen:** The entire `SpatialEngine` is gated behind a global lock screen integrated into the `HomeView`. Swiping up prompts for a PIN (`0000`). Only when unlocked can the user navigate the spatial grid.
*   **Point-Gated Application Drawer:** External Android APKs (Instagram, Browser, etc.) are listed via the `installed_apps` package within the `PreferencesDashboardView`. Launching external apps dynamically costs **Star Points** (deducted via `PointsDao`), tying regular device usage to the Gamification engine.
