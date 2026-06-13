# How to Build | Music Library

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Music Library|Music Library]]



This document outlines the step-by-step coding directives and architectural wiring instructions for developer subagents to implement the Music Library system.

---

## 1. Step-by-Step Implementation Flow

### Step 1: Go Daemon Audio Tags Scanner (Subagent Gamma)
1. **Directory Allocation:** Create the module package in `backend/host-daemon/internal/music/`.
2. **Vorbis/ID3 tag extractor:** Implement audio metadata parsing engines:
   ```go
   func ReadAudioMetadata(filePath string) (*Metadata, error) {
       // Read Vorbis comment keys or ID3 byte logs
       return extractID3Tags(filePath)
   }
   ```
3. **Subsonic Server Routing:** Set up API controllers processing Subsonic requests.

### Step 2: SQLite Drift Schema Migration (Subagent Beta)
1. **Table Mappings:** Add `MusicTracksTable`, `PlaylistsTable`, and `PlaylistTracksTable` class definitions in `client/lib/database/tables.dart`.
2. **SQLite Compilation:** Run code generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. **DAO Integration:** Define database streams delivering tracks query sets filtered by playlist identifiers.

### Step 3: Flutter audio playback UI (Subagent Beta)
1. **Everforest Colors:**
   - Scaffold canvas: `EverforestColors.bg0`.
   - Playlists containers: `EverforestColors.bg1`.
   - Outlines: 1px border lines in `EverforestColors.bg2`.
   - Highlights: `EverforestColors.fg` (headers), `grey` (labels).
2. **just_audio player integration:** Implement widget listeners updating seek controls.

### Step 4: Word Translation Hook (Subagent Alpha)
1. **Vocabulary Study bridge:** Bind lyrics selectors to Project Infinity logs:
   - Call `ProjectInfinity.addWord(lyricsWord)` upon user select events.
2. **Dirty Mark:** Set `is_dirty = 1` to command immediate synchronization loops.
