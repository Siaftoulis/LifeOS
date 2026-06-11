# What to Do | Photo Video Gallery

This document outlines the development tasks and subagent assignments for implementing the Photo Video Gallery asset manager, backups engine, and ML classifier.

---

## 1. Subagent Alpha (Lead Architect) Commands
- [ ] **DATA_SCHEMAS.md Integration:** Update the system database layout in `vault/04 - LifeOS DevDocs/DATA_SCHEMAS.md` to define relational schemas for the `media_assets` and `media_tags` tables.
- [ ] **Point Star Reward Logic:** Define tracking rules for the Point Star System:
  - Add **+1 Star Point** to the user's ledger for every 5 uploaded media assets.
- [ ] **Conflict Resolution Specifications:** Define sync conflict schemas for tag changes, ensuring client-driven Last-Write-Wins (LWW) resolution.
- [ ] **Milestone Logging:** Document all database schema updates, sync rules, and reward calculations in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) upon completion.

---

## 2. Subagent Beta (Frontend & Local Storage) Commands
- [ ] **Drift Table Generation:** Create Drift models inside `client/lib/database/` for:
  - `MediaAssets`: Fields for id, filename, file_path, file_size, file_type, latitude, longitude, capture_time, scan_status, is_dirty.
  - `MediaTags`: Fields for id, asset_id, tag_name, tag_type, confidence, is_dirty.
  - Run database code generators to create matching DAOs and stream builders.
- [ ] **Gallery Dashboard UI:** Build the main media viewer interface in `client/lib/presentation/widgets/` following the Everforest color scheme:
  - Scaffold screen canvas set to `EverforestColors.bg0`.
  - Grid viewports and image detail cards set to `EverforestColors.bg1`.
  - 1px thin outlines set to `EverforestColors.bg2` around each component card.
  - Custom typography using `EverforestColors.fg` for headers and `grey` for status labels.
- [ ] **Interactive Media View:** Build fluid image galleries presenting zoom controls and bottom-to-top gradient overlays.
- [ ] **Change Documentation:** Update the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) with details of all new Drift tables, image grids, and detail panels created.

---

## 3. Subagent Gamma (Systems, Security & Network) Commands
- [ ] **Upload and Transcode Daemon:** Write file checkers in Go (`backend/host-daemon/internal/gallery/`) saving uploaded images and compiling lightweight WebP previews.
- [ ] **EXIF Data Scanner:** Write Go routines extracting camera info and locations coordinates from uploaded files.
- [ ] **REST API Endpoints:** Register server handlers in the daemon configuration:
  - `POST /api/v1/gallery/upload`: Stream client media uploads.
  - `GET /api/v1/gallery/assets`: Paged listing query endpoint.
  - `GET /api/v1/gallery/thumbnail`: Serves WebP preview images.
- [ ] **Execution Log Update:** Record details of Go upload trackers, WebP transcoder scripts, and EXIF parsers in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) before final delivery.
