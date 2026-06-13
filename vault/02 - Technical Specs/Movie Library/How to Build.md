# How to Build | Movie Library

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Movie Library|Movie Library]]



This document outlines the step-by-step coding directives and architectural wiring instructions for developer subagents to implement the Movie Library system.

---

## 1. Step-by-Step Implementation Flow

### Step 1: Go Daemon Downloader & Scrapers (Subagent Gamma)
1. **Directory Allocation:** Create the package files in `backend/host-daemon/internal/movies/`.
2. **qBittorrent CLI Integration:** Implement Go client connectors calling transmission/qBittorrent RPC interfaces:
   ```go
   func TriggerMovieDownload(infoHash string) error {
       // Invoke client downloader REST API
       return callClientAPI("/api/v2/torrents/add", infoHash)
   }
   ```
3. **OpenSubtitles Retriever:** Implement search functions downloading translation logs.

### Step 2: SQLite Drift Schema Migration (Subagent Beta)
1. **Table Mappings:** Add `MoviesTable`, `MovieWatchlistTable`, and `MovieReviewsTable` declarations in `client/lib/database/tables.dart`.
2. **SQLite Compilation:** Run code generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. **DAO Integration:** Define stream query adapters serving watchlist timelines to the primary view controller.

### Step 3: Flutter Playback Viewport (Subagent Beta)
1. **Everforest Colors:**
   - Scaffold canvas: `EverforestColors.bg0`.
   - Grid catalogs: `EverforestColors.bg1`.
   - Outline separators: 1px border lines in `EverforestColors.bg2`.
   - Highlights: `EverforestColors.fg` (headers), `grey` (labels).
2. **VLC Controller Widget:** Integrate LibVLC native display plugins rendering high-fidelity streams.

### Step 4: Star Point Hook (Subagent Alpha)
1. **Transaction Triggers:** Register reward payouts upon catalog reviews updates:
   - Call `PointStarSystem.addPoints(5)` when movie reviews are saved.
2. **Sync Flags:** Set `is_dirty = 1` to command immediate synchronization loops.
