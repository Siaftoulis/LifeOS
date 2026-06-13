# System Design Blueprint

> [!NOTE]
> **Home:** [[04 - LifeOS DevDocs/Home|Home]]


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
