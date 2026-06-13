# What to Do | Dark Web Management

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Dark Web Management|Dark Web Management]]



This document outlines the development tasks and subagent assignments for implementing the Dark Web Management system, providing secure peer-to-peer (P2P) file sharing, isolated sandboxed downloads, and automatic malware filtering.

---

## 1. Subagent Alpha (Lead Architect) Commands
- [ ] **DATA_SCHEMAS.md Integration:** Update the system database layout in `vault/04 - LifeOS DevDocs/DATA_SCHEMAS.md` to define relational schemas for the `torrents`, `torrent_peers`, and `shared_files` tables.
- [ ] **Point Star Reward Logic:** Define tracking rules for the Point Star System:
  - Add **+1 Star Point** to the user's ledger for every 1GB of data successfully seeded to trusted friends.
  - Deduct **-10 Star Points** as a severe penalty if an uploaded file contains malware or runs prohibited executable hooks.
- [ ] **Conflict Resolution Specifications:** Define sync conflict schemas for active download/upload status vectors, ensuring client-driven Last-Write-Wins (LWW) resolution.
- [ ] **Milestone Logging:** Document all database schema updates, sync rules, and reward calculations in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) upon completion.

---

## 2. Subagent Beta (Frontend & Local Storage) Commands
- [ ] **Drift Table Generation:** Create Drift models inside `client/lib/database/` for:
  - `Torrents`: Fields for id, info_hash, name, size_bytes, progress, download_speed, upload_speed, status, is_dirty.
  - `TorrentPeers`: Fields for id, torrent_id, client_ip, bytes_exchanged, is_dirty.
  - `SharedFiles`: Fields for id, file_path, name, size_bytes, status, is_dirty.
  - Run database code generators to create matching DAOs and stream builders.
- [ ] **Torrent Dashboard UI:** Build the main torrent dashboard interface in `client/lib/presentation/widgets/` following the Everforest color scheme:
  - Scaffold screen canvas set to `EverforestColors.bg0`.
  - Torrent item list and details card panels set to `EverforestColors.bg1`.
  - 1px thin outlines set to `EverforestColors.bg2` around each component card.
  - Custom typography using `EverforestColors.fg` for headers and `grey` for speed/size stats.
- [ ] **Private Tracker Generator UI:** Build visual screens for generating custom magnet links directly from local library files, linking to the user's selected file path.
- [ ] **Security Warnings Console:** Build an alert grid panel showing file sandboxing logs and quarantine lists, highlighting threats in red and safe logs in green.
- [ ] **Change Documentation:** Update the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) with details of all new Drift tables, active downloads lists, and tracker generators created.

---

## 3. Subagent Gamma (Systems, Security & Network) Commands
- [ ] **P2P Torrent Client Wrapper:** Write background wrappers in Go (`backend/host-daemon/internal/darkweb/`) to interface with daemon torrent clients (such as transmission-daemon) over private Tailnet links.
- [ ] **Inbound Security Inspection Loop:** Write file scan automation scripts executing `clamdscan` binary checks on a sandbox directory:
  - If malware is found, immediately delete the binary, notify the database, and write 'infected' status to the `shared_files` table.
  - If safe, move the file to user-accessible storage arrays for client retrieval.
- [ ] **REST API Sync Endpoints:** Register server handlers in the daemon configuration:
  - `GET /api/v1/darkweb/torrents`: List all cataloged entries.
  - `POST /api/v1/darkweb/torrents/add`: Queue new magnet links.
  - `POST /api/v1/darkweb/torrents/delete`: Delete torrent files and clean metadata.
- [ ] **Execution Log Update:** Record details of Go torrent wrappers, ClamAV filters, and secure P2P tracking in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) before final delivery.
