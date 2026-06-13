# How to Build | YouTube Client

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/YouTube Client|YouTube Client]]



This document outlines the step-by-step coding directives and architectural wiring instructions for developer subagents to implement the YouTube Client system.

---

## 1. Step-by-Step Implementation Flow

### Step 1: Go Daemon yt-dlp Video Ingestion (Subagent Gamma)
1. **Directory Allocation:** Create the package in `backend/host-daemon/internal/youtube/`.
2. **yt-dlp shell execution:** Implement Go routines to run background video downloads:
   ```go
   func StartVideoDownload(videoURL string, outputPath string) error {
       cmd := exec.Command("yt-dlp", "-o", outputPath, videoURL)
       return cmd.Run()
   }
   ```
3. **Session Checkers:** Write rules checking user balances coordinates.

### Step 2: SQLite Drift Schema Migration (Subagent Beta)
1. **Table Mappings:** Add `YoutubeSessionsTable` and `YoutubeDownloadsTable` declarations in `client/lib/database/tables.dart`.
2. **SQLite Compilation:** Run code generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. **DAO Integration:** Define dynamic database queries mapping offline videos items lists to local streams.

### Step 3: Flutter Playback viewport & Gated UI (Subagent Beta)
1. **Everforest Colors:**
   - Scaffold canvas: `EverforestColors.bg0`.
   - Grid cards: `EverforestColors.bg1`.
   - Outline separators: 1px border lines in `EverforestColors.bg2`.
   - Alerts: `red` (lockout warnings), `grey` (details).
2. **Timer overlays grid:** Build floating overlay cards indicating active session timers.

### Step 4: Points Deductions Hook (Subagent Alpha)
1. **Screen time deductions:** Register point deductions triggers inside session trackers:
   - Call `PointStarSystem.deductPoints(10)` per 30 minutes.
2. **Sync Flags:** Set `is_dirty = 1` to command immediate synchronization loops.
