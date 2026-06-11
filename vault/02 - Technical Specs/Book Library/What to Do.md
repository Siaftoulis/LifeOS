# What to Do | Book Library

This document outlines the development tasks and subagent assignments for implementing the Book Library, incorporating e-book reading, audiobook playback, progress syncing, and a Kindle-compatible web interface.

---

## 1. Subagent Alpha (Lead Architect) Commands
- [ ] **DATA_SCHEMAS.md Integration:** Update the system database layout in `vault/04 - LifeOS DevDocs/DATA_SCHEMAS.md` to define relational schemas for the `books`, `audiobooks`, `reading_progress`, and `highlights` tables.
- [ ] **Point Star Reward Logic:** Define tracking rules for the Point Star System:
  - Add **+1 Star Point** to the user's ledger for every 10 pages read.
  - Add **+1 Star Point** to the user's ledger for every 15 minutes of audiobook listening.
  - Add **+2 Star Points** for exporting annotations and highlights to the Obsidian Zen Editor.
- [ ] **Conflict Resolution Specifications:** Define sync conflict schemas for reading progress timestamps, ensuring Last-Write-Wins (LWW) resolution.
- [ ] **Milestone Logging:** Document all database schema updates, sync rules, and reward calculations in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) upon completion.


---

## 2. Subagent Beta (Frontend & Local Storage) Commands
- [ ] **Drift Table Generation:** Create Drift models inside `client/lib/database/` for:
  - `Books`: Fields for id, title, author, total_pages, current_page, text_file_path.
  - `Audiobooks`: Fields for id, book_id, audio_file_path, duration_seconds, current_seconds.
  - `ReadingProgress`: Fields for book_id, last_accessed, position_percentage, is_dirty.
  - `Highlights`: Fields for id, book_id, text_content, note_content, created_at, is_dirty.
  - Run database code generators to create matching DAOs and stream builders.
- [ ] **Book Library Dashboard UI:** Build the main library grid interface in `client/lib/presentation/widgets/` following the Everforest color scheme:
  - Scaffold screen canvas set to `EverforestColors.bg0`.
  - Bookshelf grid cells and player control panels set to `EverforestColors.bg1`.
  - 1px thin outlines set to `EverforestColors.bg2` around each component card.
  - Custom typography using `EverforestColors.fg` for headers and `grey` for author details.
- [ ] **Embedded EPUB Reader Widget:** Implement a local text rendering parser screen. Read EPUB chapter structures using a clean text viewport with custom text sizes and fonts, capturing page-turn updates to increment page counts and trigger the database progress logs.
- [ ] **Audiobook Playback Widget:** Implement an audio player panel supporting:
  - Play, pause, skip forward 30s, skip backward 15s.
  - A slider representing current playback position linked to the `Audiobooks` progress stream.
  - Synchronized bookmarks mapping audio timestamps to estimated e-book pages.
  - Smartwatch layout fallback (compact playback buttons with no text descriptors).
- [ ] **Zen Editor Highlight Export:** Create an interactive highlight list panel. Tapping a highlight card must automatically format the text into an Obsidian note link and append it to the active folder in the Obsidian Zen Editor, awarding the user Star Points.
- [ ] **Change Documentation:** Update the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) with details of all new Drift tables, EPUB reader integrations, and UI components created for the Book Library.


---

## 3. Subagent Gamma (Systems, Security & Network) Commands
- [ ] **Accept-Ranges Audio Streamer:** Write the audiobook file streamer in Go (`backend/host-daemon/internal/books/`) using high-performance HTTP byte-range serving to support streaming M4B/MP3 audiobooks with random seek features on mobile clients.
- [ ] **Kindle high-contrast Web UI:** Host a minimal high-contrast HTML reader page served on port 8080. It must query the books table and serve pure, high-contrast black-and-white layouts readable on Kindle experimental browsers.
- [ ] **VPN-Routed Scraping and Downloader:** Write background search hooks in Go executing search commands over secure channels using a local routing client or Tailscale exit node to download public domain/purchased text and audio files directly to the server's storage path.
- [ ] **JSON-RPC Sync API:** Register server handlers in the daemon configuration:
  - `GET /api/v1/books`: List all cataloged entries.
  - `POST /api/v1/books/progress`: Sync current page position and audio timestamps.
  - `POST /api/v1/books/highlight`: Push annotations from the client directly into the server's sync queue.
- [ ] **Execution Log Update:** Record details of the Go media streamer, Kindle web portal reader, and VPN downloader in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) before final delivery.

