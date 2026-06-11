# What to Do | Music Library

This document outlines the development tasks and subagent assignments for implementing the Music Library audio streamer, playlists controller, and lyrics engine.

---

## 1. Subagent Alpha (Lead Architect) Commands
- [ ] **DATA_SCHEMAS.md Integration:** Update the system database layout in `vault/04 - LifeOS DevDocs/DATA_SCHEMAS.md` to define relational schemas for the `music_tracks`, `playlists`, and `playlist_tracks` tables.
- [ ] **Point Star Reward Logic:** Define tracking rules for the Point Star System:
  - Add **+2 Star Points** to the user's ledger for completing lyrics translation study checks.
- [ ] **Conflict Resolution Specifications:** Define sync conflict schemas for playlist indexes, ensuring client-driven Last-Write-Wins (LWW) resolution.
- [ ] **Milestone Logging:** Document all database schema updates, sync rules, and reward calculations in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) upon completion.

---

## 2. Subagent Beta (Frontend & Local Storage) Commands
- [ ] **Drift Table Generation:** Create Drift models inside `client/lib/database/` for:
  - `MusicTracks`: Fields for id, title, artist, album, track_number, file_path, lyrics_path, is_dirty.
  - `Playlists`: Fields for id, name, created_at, is_dirty.
  - `PlaylistTracks`: Fields for id, playlist_id, track_id, is_dirty.
  - Run database code generators to create matching DAOs and stream builders.
- [ ] **Music Dashboard UI:** Build the main media cloud interface in `client/lib/presentation/widgets/` following the Everforest color scheme:
  - Scaffold screen canvas set to `EverforestColors.bg0`.
  - Playlist details and music player sheets set to `EverforestColors.bg1`.
  - 1px thin outlines set to `EverforestColors.bg2` around each component card.
  - Custom typography using `EverforestColors.fg` for headers and `grey` for status labels.
- [ ] **just_audio player interface:** Integrate audio player panels presenting progress seek bars and lyrics timelines.
- [ ] **Change Documentation:** Update the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) with details of all new Drift tables, playlist layouts, and smartwatch controller hooks.

---

## 3. Subagent Gamma (Systems, Security & Network) Commands
- [ ] **Recursive Directory Scanner:** Write scanner functions in Go (`backend/host-daemon/internal/music/`) parsing folders for ID3 metadata.
- [ ] **Accept-Ranges Audio Server:** Write audio range streamers in Go delivering FLAC/MP3 files.
- [ ] **REST API Endpoints:** Register server handlers in the daemon configuration:
  - `GET /api/v1/music/tracks`: List local audio files databases.
  - `GET /api/v1/music/stream`: Serve target track files byte ranges.
  - `GET /api/v1/music/lyrics`: Query time-synced lyrics files.
- [ ] **Execution Log Update:** Record details of Go media indexes, Subsonic-compatible APIs, and lyrics collectors in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) before final delivery.
