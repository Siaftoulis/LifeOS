# What to Do | Movie Library

This document outlines the development tasks and subagent assignments for implementing the Movie Library media catalog, watchlist queue, and player wrapper.

---

## 1. Subagent Alpha (Lead Architect) Commands
- [ ] **DATA_SCHEMAS.md Integration:** Update the system database layout in `vault/04 - LifeOS DevDocs/DATA_SCHEMAS.md` to define relational schemas for the `movies`, `movie_watchlist`, and `movie_reviews` tables.
- [ ] **Point Star Reward Logic:** Define tracking rules for the Point Star System:
  - Add **+5 Star Points** to the user's ledger for writing detailed movie reviews.
- [ ] **Conflict Resolution Specifications:** Define sync conflict schemas for watchlist status states, ensuring Last-Write-Wins (LWW) resolution.
- [ ] **Milestone Logging:** Document all database schema updates, sync rules, and reward calculations in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) upon completion.

---

## 2. Subagent Beta (Frontend & Local Storage) Commands
- [ ] **Drift Table Generation:** Create Drift models inside `client/lib/database/` for:
  - `Movies`: Fields for id, title, imdb_id, cover_path, file_path, status, is_dirty.
  - `MovieWatchlist`: Fields for id, movie_id, added_at, priority, is_dirty.
  - `MovieReviews`: Fields for id, movie_id, rating, comment, is_dirty.
  - Run database code generators to create matching DAOs and stream builders.
- [ ] **Movies Dashboard UI:** Build the main media catalog grid in `client/lib/presentation/widgets/` following the Everforest color scheme:
  - Scaffold screen canvas set to `EverforestColors.bg0`.
  - Movie cards and playback overlays set to `EverforestColors.bg1`.
  - 1px thin outlines set to `EverforestColors.bg2` around each component card.
  - Custom typography using `EverforestColors.fg` for headers and `grey` for status labels.
- [ ] **LibVLC Video player overlay:** Integrate VLC controllers presenting standard media controls and dynamic subtitle sliders.
- [ ] **Change Documentation:** Update the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) with details of all new Drift tables, VLC controllers, and catalog cards created.

---

## 3. Subagent Gamma (Systems, Security & Network) Commands
- [ ] **Metadata Scraper Daemon:** Write scraper functions in Go (`backend/host-daemon/internal/movies/`) parsing IMDb/TMDb APIs.
- [ ] **Downloader API Wrapper:** Write Go routines to pass media tasks to local clients (such as qBittorrent) over secure VPN networks.
- [ ] **REST API Endpoints:** Register server handlers in the daemon configuration:
  - `GET /api/v1/movies`: List local and metadata media databases.
  - `POST /api/v1/movies/watchlist`: Push items to the download pipeline.
  - `GET /api/v1/movies/subtitles`: Query OpenSubtitles translation lists.
- [ ] **Execution Log Update:** Record details of Go metadata trackers, VLC wrappers, and OpenSubtitles pipelines in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) before final delivery.
