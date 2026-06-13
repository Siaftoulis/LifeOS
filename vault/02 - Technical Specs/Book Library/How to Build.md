# How to Build | Book Library

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Book Library|Book Library]]



This document outlines the step-by-step coding directives and architectural wiring instructions for developer subagents to implement the Book Library.

---

## 1. Step-by-Step Implementation Flow

### Step 1: Go Backend Media Streaming & Ingestion (Subagent Gamma)
1. **Directory Allocation:** Create the module handler in `backend/host-daemon/internal/books/`.
2. **Audio Streaming:** Implement a standard Go HTTP handler matching:
   ```go
   func StreamAudiobookHandler(w http.ResponseWriter, r *http.Request) {
       audioID := r.URL.Query().Get("id")
       filePath := getAudiobookPath(audioID) // resolve from DB
       http.ServeFile(w, r, filePath) // handles Range: bytes automatically
   }
   ```
3. **Kindle Web Interface:** Write an HTML generator function that reads raw EPUB texts and parses them into plain HTML blocks with no CSS styling, serving it specifically to devices reporting Kindle browser User-Agents.
4. **VPN-Scraper Interface:** Wire search functions to query target libraries through an internal proxy or active VPN gateway context (`tsnet` outbound client).

### Step 2: SQLite Drift Schema Migration (Subagent Beta)
1. **Table Mappings:** Add `BooksTable`, `AudiobooksTable`, `ReadingProgressTable`, and `BookHighlightsTable` class representations in `client/lib/database/tables.dart`.
2. **SQLite Compilation:** Run `flutter pub run build_runner build` to refresh the compiled database models.
3. **DAO Integration:** Define custom select methods to extract reading progress data reactively using Flutter Stream builders.

### Step 3: Flutter Reading Core UI Implementation (Subagent Beta)
1. **Everforest Colors:**
   - Backgrounds: Use `bg0` for scaffolds.
   - Text reading pane: Set background to `bg1` (high contrast, minimal eye strain).
   - Card border borders: Wrap containers inside `bg2` styled frames.
   - Headers and page counters: Render in `fg` and `grey` labels.
2. **EPUB Reader Configuration:**
   - Integrate an open-source parsing module to read page offsets.
   - Capture user drag coordinates. Highlight select text strings and prompt the highlight options popup.
3. **Progress Estimation Calculations:**
   - When switching between e-book text reading and audio listening, the local database must calculate bookmark conversions using the dynamic ratios:
     $$\text{Estimated Audio Position (seconds)} = \text{Current Page} \times \left( \frac{\text{Total Duration (seconds)}}{\text{Total Pages}} \right)$$
     $$\text{Estimated Page} = \text{Current Audio Position (seconds)} \times \left( \frac{\text{Total Pages}}{\text{Total Duration (seconds)}} \right)$$
   - These dynamic estimates must automatically update the database progress state vector when switching modes.

### Step 4: Star Point Calculation Hook (Subagent Alpha)
1. **Ledger Updates:** Intercept page completion and audio listen loops inside database transaction triggers:
   - Call `PointStarSystem.addPoints(1)` upon every increment of 10 pages read.
   - Call `PointStarSystem.addPoints(1)` upon every 15 minutes (900 seconds) of confirmed audiobook playback.
   - Call `PointStarSystem.addPoints(2)` upon exporting highlights to the Obsidian Zen Editor database.
2. **Dirty Flags:** Mark mutated rows with `is_dirty = 1` to command immediate Tailscale syncing.
