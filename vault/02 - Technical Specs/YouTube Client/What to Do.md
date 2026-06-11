# What to Do | YouTube Client

This document outlines the development tasks and subagent assignments for implementing the YouTube Client, managing timed screen gates, point star deductions, and download caching pipelines.

---

## 1. Subagent Alpha (Lead Architect) Commands
- [ ] **DATA_SCHEMAS.md Integration:** Update the system database layout in `vault/04 - LifeOS DevDocs/DATA_SCHEMAS.md` to define relational schemas for the `youtube_sessions` and `youtube_downloads` tables.
- [ ] **Point Star Reward Logic:** Define tracking rules for the Point Star System:
  - Deduct **-10 Star Points** from the user's ledger for every 30 minutes of YouTube video consumption.
- [ ] **Conflict Resolution Specifications:** Define sync conflict schemas for video downloads lists, ensuring client-driven Last-Write-Wins (LWW) resolution.
- [ ] **Milestone Logging:** Document all database schema updates, sync rules, and reward calculations in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) upon completion.

---

## 2. Subagent Beta (Frontend & Local Storage) Commands
- [ ] **Drift Table Generation:** Create Drift models inside `client/lib/database/` for:
  - `YoutubeSessions`: Fields for id, user_id, start_time, duration_seconds, cost_points, is_dirty.
  - `YoutubeDownloads`: Fields for id, video_id, title, file_path, size_bytes, is_dirty.
  - Run database code generators to create matching DAOs and stream builders.
- [ ] **Launcher Dashboard UI:** Build the social media gateway player screen in `client/lib/presentation/widgets/` following the Everforest color scheme:
  - Scaffold screen canvas set to `EverforestColors.bg0`.
  - Active video grids and download playlists cards set to `EverforestColors.bg1`.
  - 1px thin outlines set to `EverforestColors.bg2` around each component card.
  - Custom typography using `EverforestColors.fg` for headers and `grey` for video details.
- [ ] **Gated Timer overlay:** Build floating timer widgets showing points cost and countdown clocks.
- [ ] **Change Documentation:** Update the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) with details of all new Drift tables, active download play managers, and timer overlays created.

---

## 3. Subagent Gamma (Systems, Security & Network) Commands
- [ ] **yt-dlp Video Downloader:** Write CLI wrapper routines in Go (`backend/host-daemon/internal/youtube/`) executing background downloads via the local `yt-dlp` executable.
- [ ] **Session Gate Watcher:** Write server cron checking points ledger limits, sending lock alerts when balances drop below zero.
- [ ] **REST API Endpoints:** Register server handlers in the daemon configuration:
  - `GET /api/v1/youtube/videos`: List downloaded offline videos list.
  - `POST /api/v1/youtube/download`: Trigger background video caching pipelines.
  - `POST /api/v1/youtube/session/start`: Init session trackers and points check.
  - `POST /api/v1/youtube/session/stop`: Finalize session timelines and execute points updates.
- [ ] **Execution Log Update:** Record details of Go yt-dlp pipelines and session trackers in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) before final delivery.
