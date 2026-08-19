---
id: "00000000-0000-0000-0000-000000000000"
type: "lifeos_documentation_home"
last_modified: 1784500000000
sync_status: "clean"
---

> [!NOTE]
> **System Home:** [[00 - System/Home|System Home]] | **Active Work:** [[03 - work/Step_Trace_Log|Step Trace Log]] · [[03 - work/current_sprint.json|Current Sprint]] · [[03 - work/subagent_delegation|Subagent Delegation]] · [[03 - work/system_architecture|System Architecture]]

# LifeOS Systems Specification Vault

Welcome to the central system design repository for the personal **LifeOS** platform. These technical specifications detail the offline-first, local-first architectures for native desktop, mobile, and web environments.

> [!TIP]
> **Current State (August 2026):** LifeOS v1.5.0 (build 33). Flutter client (Android/Windows/Web) + Go host daemon + Go sync relay. Global JWT auth gate, GitHub/Google OAuth SSO, Flutter web portal served by the daemon and published via Tailscale Funnel (`https://lifeos-host.husky-forel.ts.net`). All 20 modules implemented; the daemon exposes ~38 domain packages behind `/api/v1/<domain>`.

---

## Core Architecture Specifications

### [[04 - LifeOS DevDocs/BACKEND_ARCHITECTURE|Backend Architecture]]
*   Single Go daemon (`backend/host-daemon`), one API with per-domain route groups, per-module SQLite databases in `data/`, global JWT gate, events bus, automations engine.

### [[04 - LifeOS DevDocs/INTEGRATION_PLAN|Integration Plan (One API)]]
*   The 2026-08-11 design decisions: one API, backend-only external keys, reference-not-copy entities, local-first storage, `?q=` search on every domain endpoint, Zen Editor entity embeds.

### [[04 - LifeOS DevDocs/SECURITY_MODEL|Security Model]]
*   WireGuard transport, JWT auth gate with public allowlist, OAuth SSO with CSRF protection, invite-only public registration, Child Lock RBAC, secrets inventory, web hardening.

### [[04 - LifeOS DevDocs/WEB_FAILSAFE|Web Portal & Fail-Safe Layer]]
*   Flutter web portal served at `/` by the daemon; Tailscale Funnel `:443 → :50052`; `publicOnly` policy; no-cache + purged service worker; MD5-verified deploys; alternative dockerized oauth2-proxy stack.

### [[04 - LifeOS DevDocs/EMBEDDED_NETWORK|On-Demand User-Space Mesh (tsnet)]]
*   Embedded `tsnet` user-space mesh (host `lifeos-host`, port `:50051`), zero-click auth, port map (50051/50052/8080/18785/4444), Funnel enablement, custom DDNS.

### [[04 - LifeOS DevDocs/DATA_SCHEMAS|Data Schemas & Storage]]
*   Client Drift schema (60 tables, WAL) + daemon per-module SQLite databases + JSON stores; YAML frontmatter parsing rules; LWW sync rules.

### [[04 - LifeOS DevDocs/SYNC_PROTOCOL|Transactional Change Logging Sync Protocol]]
*   Delta-based dirty-record sync (base64+gzip push), Last-Write-Wins resolution, events WebSocket bus, Yjs CRDT collab relay, zen tombstones, vault watcher.

### [[04 - LifeOS DevDocs/STATE_MANAGEMENT|Client State Management]]
*   Drift reactive streams + 20 DAOs, ApiClient with offline buffer queue, AuthService with Local Mode fallback, EventHub WebSocket bus, spatial engine state, custom sync manager.

### [[04 - LifeOS DevDocs/INFRASTRUCTURE_CONTROL|Infrastructure Control & Virtualization]]
*   Host daemon remote actions: Wake-on-LAN, Hyper-V control, `/api/v1/vm` endpoints, RustDesk self-hosted remote desktop, remote file explorer.

### [[04 - LifeOS DevDocs/DEPLOYMENT_CI_CD|Deployment & CI/CD]]
*   GitHub Actions `release.yml` (APK + Windows zip on `v*` tags), `deploy_server.ps1` production deploys via Tailscale SSH, versioning conventions.

---

## Game Systems & Workflows

- [[04 - LifeOS DevDocs/RPG_PLAYER_CARD_SYSTEM|RPG Player Card System]] — XP, attributes, leveling
- [[04 - LifeOS DevDocs/LEVELING_FORMULAS|Leveling Formulas]] — Sigmoid cap math
- [[04 - LifeOS DevDocs/ATTRIBUTE_ATROPHY_MECHANICS|Attribute Atrophy Mechanics]] — XP decay
- [[04 - LifeOS DevDocs/ILLNESS_INJURY_SYSTEM|Illness & Injury System]] — Recovery mechanics
- [[04 - LifeOS DevDocs/UNIFIED_HABIT_TASK_FLOW|Unified Habit & Task Flow]] — CHTM → RPG rewards pipeline
- [[04 - LifeOS DevDocs/Aves_Local_AI_Tagging|Aves Local AI Tagging]] — Gallery smart picker

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

## Reference & Analysis
- [[04 - LifeOS DevDocs/Codebase_Analysis|Codebase Analysis]] — August 2026 full-stack snapshot
- [[04 - LifeOS DevDocs/PROXY_SETUP|Proxy Setup]] — Reverse proxy / oauth2-proxy docker stack
- [[04 - LifeOS DevDocs/REFACTOR_PLAN|Refactor Plan]] — Legacy refactor roadmap
- [[04 - LifeOS DevDocs/Raw_Subagent_Reports|Raw Subagent Reports]] — Historical agent analysis output
- [[04 - LifeOS DevDocs/UI_UX_GUIDELINES|UI/UX Guidelines]] — Everforest design system