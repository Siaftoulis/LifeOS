---
id: "00000000-0000-0000-0000-000000000000"
type: "lifeos_documentation_home"
last_modified: 1779951600000
sync_status: "clean"
---

# LifeOS Systems Specification Vault

Welcome to the central system design repository for the personal **LifeOS** platform. These technical specifications detail the offline-first, local-first architectures for native desktop and mobile environments.

---

## Core Architecture Specifications

Select a specification below to view its design architecture:

### [1. Split-Storage & Frontmatter Architecture](DATA_SCHEMAS.md)
*   **Database Engine:** SQLite schema definitions for habits, tasks, check-ins, state fields, and synchronizability attributes.
*   **Knowledge Base Integration:** Parsers and properties mappings for YAML frontmatter blocks inside local Obsidian `.md` notes.

### [2. On-Demand User-Space Mesh (tsnet)](EMBEDDED_NETWORK.md)
*   **Tunneling Engine:** Deep-dive into embedded `tsnet` user-space mesh networks (Windows `.dll` Cgo targets, Android `.aar` Go Mobile bindings).
*   **Zero-Click Auth:** Security procedures using the Windows Credential Manager and Android Keystore to log in securely without key exposure.

### [3. Web Fail-Safe Layer (Zero-Trust Proxy)](WEB_FAILSAFE.md)
*   **Fallback Access:** Secure browser-based interaction via Zrok Public Shares or Tailscale Funnel.
*   **Zero-Trust Edge:** Strict Google/GitHub OAuth identity validation blocks unauthorized requests before hitting internal reverse proxies.

### [4. Infrastructure Control & Virtualization](INFRASTRUCTURE_CONTROL.md)
*   **LifeOS Host Daemon:** Background Windows 11 service for remote Hyper-V/Docker execution, Wake-on-LAN, and file streaming.
*   **Remote Desktop Integration:** Open-source RustDesk and Sunshine high-performance GPU streaming configurations.

### [5. Transactional Change Logging Sync Protocol](SYNC_PROTOCOL.md)
*   **Delta-Based Syncing:** Design of a dedicated database-backed `sync_queue` table capturing atomic property-level change events rather than full file content rewrites.
*   **Eventual Consistency:** Fully deterministic client-driven Last-Write-Wins (LWW) conflict resolution logic using NTP-aligned mutation timestamps.

---

## Monorepo Workspace Context

This vault is part of the `lifeos-monorepo` structural design. Refer to [.agent/system_architecture.md](../../.agent/system_architecture.md) for structural blueprints, data flows, and platform targets.
