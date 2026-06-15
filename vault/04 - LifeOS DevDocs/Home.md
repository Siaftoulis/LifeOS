---
id: "00000000-0000-0000-0000-000000000000"
type: "lifeos_documentation_home"
last_modified: 1779951600000
sync_status: "clean"
---

> [!NOTE]
> **System Home:** [[00 - System/Home|System Home]] | **Active Work:** [[03 - work/Step_Trace_Log|Step Trace Log]] · [[03 - work/current_sprint.json|Current Sprint]] · [[03 - work/subagent_delegation|Subagent Delegation]] · [[03 - work/system_architecture|System Architecture]]

# LifeOS Systems Specification Vault

Welcome to the central system design repository for the personal **LifeOS** platform. These technical specifications detail the offline-first, local-first architectures for native desktop and mobile environments.

---

## Core Architecture Specifications

Select a specification below to view its design architecture:

### [[04 - LifeOS DevDocs/DATA_SCHEMAS|1. Split-Storage & Frontmatter Architecture]]
*   **Database Engine:** SQLite schema definitions for habits, tasks, check-ins, state fields, and synchronizability attributes.
*   **Knowledge Base Integration:** Parsers and properties mappings for YAML frontmatter blocks inside local Obsidian `.md` notes.

### [[04 - LifeOS DevDocs/EMBEDDED_NETWORK|2. On-Demand User-Space Mesh (tsnet)]]
*   **Tunneling Engine:** Deep-dive into embedded `tsnet` user-space mesh networks (Windows `.dll` Cgo targets, Android `.aar` Go Mobile bindings).
*   **Zero-Click Auth:** Security procedures using the Windows Credential Manager and Android Keystore to log in securely without key exposure.

### [[04 - LifeOS DevDocs/WEB_FAILSAFE|3. Web Fail-Safe Layer (Zero-Trust Proxy)]]
*   **Fallback Access:** Secure browser-based interaction via Zrok Public Shares or Tailscale Funnel.
*   **Zero-Trust Edge:** Strict Google/GitHub OAuth identity validation blocks unauthorized requests before hitting internal reverse proxies.

### [[04 - LifeOS DevDocs/INFRASTRUCTURE_CONTROL|4. Infrastructure Control & Virtualization]]
*   **LifeOS Host Daemon:** Background Windows 11 service for remote Hyper-V/Docker execution, Wake-on-LAN, and file streaming.
*   **Remote Desktop Integration:** Open-source RustDesk and Sunshine high-performance GPU streaming configurations.

### [[04 - LifeOS DevDocs/SYNC_PROTOCOL|5. Transactional Change Logging Sync Protocol]]
*   **Delta-Based Syncing:** Design of a dedicated database-backed `sync_queue` table capturing atomic property-level change events rather than full file content rewrites.
*   **Eventual Consistency:** Fully deterministic client-driven Last-Write-Wins (LWW) conflict resolution logic using NTP-aligned mutation timestamps.

---

## Monorepo Workspace Context

This vault is part of the `lifeos-monorepo` structural design. Refer to [[03 - work/system_architecture|system_architecture]] for structural blueprints, data flows, and platform targets.

---

## Architecture Sub-Specifications
- [[04 - LifeOS DevDocs/Architecture/System_Design|System Design]] — Full system architecture blueprint
- [[04 - LifeOS DevDocs/Architecture/Core_UI_Dashboard|Core UI Dashboard]] — Adaptive breakpoint system and layout
- [[04 - LifeOS DevDocs/Architecture/Widget_System|Widget System]] — Native desktop and mobile widgets
- [[04 - LifeOS DevDocs/Architecture/Data_Binding|Data Binding]] — Drift reactive streams and API client
- [[04 - LifeOS DevDocs/Architecture/Custom_Sync_Engine|Custom Sync Engine]] — LWW state vectors and delta chunking
- [[04 - LifeOS DevDocs/Architecture/Test_Environment|Test Environment]] — Wireless ADB and OTA deployment
- [[04 - LifeOS DevDocs/Architecture/Web_Failsafe|Web Failsafe]] — Zero-trust web gateway architecture
- [[04 - LifeOS DevDocs/Schemas/Database_Specs|Database Specs]] — Full database schema reference
- [[04 - LifeOS DevDocs/Schemas/Sync_Protocols|Sync Protocols]] — Protocol-level sync specification
- [[04 - LifeOS DevDocs/Sprints/Step_Trace_Log|Sprint Trace Log]] — Sprint-level milestone tracking
