# LifeOS Workspace Map of Content

> [!NOTE]
> **DevDocs Home:** [[04 - LifeOS DevDocs/Home|DevDocs Home]]

Welcome to the central documentation vault for the LifeOS application. This vault houses the design concepts, philosophies, and roadmaps for each core module (tile) of the system.

---

## Navigation Matrix

### Core & Interface
- [[Home Screen]]: The primary portal and entry grid of the spatial engine.
- [[Preferences Setting Tab]]: General configuration, theme settings, and telemetry.
- [[Obsidian Zen Editor]]: The persistent markdown notes workspace and auto-save hub.

### Productivity & Organization
- [[Calendar Habit Task Manager]]: Merged scheduling, habit-tracking, and task lists.
- [[Project Infinity]]: Development tracking and infinity task mapping.
- [[Flashcards]]: Conceptual revision and active recall database.
- [[Knowledge Base]]: The central structured second-brain data collection.

### Media & Culture
- [[Photo Video Gallery]]: Dynamic media asset indexing and local previewing.
- [[Movie Library]]: Personal media library catalogs and statistics tracking.
- [[Book Library]]: E-book listings, reading status, and library management.
- [[Music Library]]: Personal music server, streaming, and offline playback.

### Environment & Virtualization
- [[Virtual Machine Management]]: Controls and views for Hyper-V environments.
- [[Cloud & Fake Virtual Machine]]: Cloud resource binding and virtual emulation.

### Maps & Live Tracking
- [[Maps & Live Tracking]]: Live Tailscale/WebSocket client positioning and telemetry tracking.

### System Control & Security
- [[Home Management]]: Smart home integration control panels.
- [[Dark Web Management]]: Security audit trackers and dark-web telemetry scanners.
- [[Point Star System]]: Gamified progress feedback loop and achievement framework.
- [[YouTube Client]]: Integrated search, streaming, and caching client.

### Financials & Ledger
- [[Banking System]]: Account balances, ledger syncing, and transaction controls.
- [[Accounting]]: Business and personal bookkeeping sheets.

---

## Technical Specifications
Detailed implementation instructions, database tables, API schemas, and step-by-step development guidelines for each module are organized under the `02 - Technical Specs` directory.

Each tile has its own subfolder containing:
- **[[02 - Technical Specs/<Module>/What to Do|What to Do]]:** Checklist of development tasks and features.
- **[[02 - Technical Specs/<Module>/What to Build|What to Build]]:** SQLite database schemas, API parameters, and Flutter widgets.
- **[[02 - Technical Specs/<Module>/How to Build|How to Build]]:** Coding directions and state binding steps.

> [!TIP]
> Each tile's **Next Steps** section outlines the development roadmap — check the individual tile files for upcoming work.

---

## LifeOS DevDocs (Architecture & Design System)
The [[04 - LifeOS DevDocs/Home|DevDocs]] directory contains all system-level technical specifications:

### Core Specifications
- [[04 - LifeOS DevDocs/DATA_SCHEMAS|DATA_SCHEMAS]] — SQLite database tables, caching, frontmatter patterns
- [[04 - LifeOS DevDocs/EMBEDDED_NETWORK|EMBEDDED_NETWORK]] — tsnet lifecycle and Tailscale authentication
- [[04 - LifeOS DevDocs/SYNC_PROTOCOL|SYNC_PROTOCOL]] — Transactional field-level delta sync engine
- [[04 - LifeOS DevDocs/WEB_FAILSAFE|WEB_FAILSAFE]] — Zero-trust proxy architecture
- [[04 - LifeOS DevDocs/INFRASTRUCTURE_CONTROL|INFRASTRUCTURE_CONTROL]] — Hyper-V, Docker, WOL infrastructure

### Architecture Blueprints
- [[04 - LifeOS DevDocs/Architecture/System_Design|System Design]]
- [[04 - LifeOS DevDocs/Architecture/Core_UI_Dashboard|Core UI Dashboard]]
- [[04 - LifeOS DevDocs/Architecture/Widget_System|Widget System]]
- [[04 - LifeOS DevDocs/Architecture/Data_Binding|Data Binding]]
- [[04 - LifeOS DevDocs/Architecture/Custom_Sync_Engine|Custom Sync Engine]]
- [[04 - LifeOS DevDocs/Architecture/Test_Environment|Test Environment]]
- [[04 - LifeOS DevDocs/Architecture/Web_Failsafe|Web Failsafe]]

### Database & Protocol Schemas
- [[04 - LifeOS DevDocs/Schemas/Database_Specs|Database Specs]]
- [[04 - LifeOS DevDocs/Schemas/Sync_Protocols|Sync Protocols]]

---

## Active Workspace & Sprint Tracking
Active registries, task logs, subagent boundaries, and system blueprints are tracked under the `03 - work` directory:
- [[Step_Trace_Log]]: The historical ledger of all architectural milestones.
- [[03 - work/current_sprint.json|current_sprint.json]]: Task checklist registry.
- [[03 - work/subagent_delegation|subagent_delegation]]: Scopes and boundaries for Alpha, Beta, and Gamma.
- [[03 - work/system_architecture|system_architecture]]: System architecture and data flow diagrams.
- [[04 - LifeOS DevDocs/Sprints/Step_Trace_Log|DevDocs Sprint Log]]: Sprint-specific trace log.

---

## Vault Guidelines
- **No Emojis:** All documents must remain free of emoji characters in headers, titles, and templates.
- **Bidirectional Linking:** Always use Obsidian style `[[Link]]` syntax to reference connected modules (e.g., how [[Accounting]] hooks into the [[Banking System]]).
- **Process Documentation:** Focus documentation on capturing the user's conceptual design and original intent, rather than just dry technical code blocks.
