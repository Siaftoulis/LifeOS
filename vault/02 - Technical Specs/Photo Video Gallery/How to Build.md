# How to Build | Photo Video Gallery

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Photo Video Gallery|Photo Video Gallery]]



This document outlines the step-by-step coding directives and architectural wiring instructions for developer subagents to implement the Photo Video Gallery.

---

## 1. Step-by-Step Implementation Flow

### Step 1: Go Daemon Transcoding & EXIF Parsing (Subagent Gamma)
1. **Directory Allocation:** Create the package files in `backend/host-daemon/internal/gallery/`.
2. **WebP Thumbnail Converter:** Implement image processing routes generating WebP preview caches:
   ```go
   func GenerateThumbnail(srcPath string, destPath string) error {
       // Open image, scale dimensions, and encode WebP output
       return createWebPThumb(srcPath, destPath, 200, 200)
   }
   ```
3. **EXIF coordinates reader:** Integrate libraries scanning metadata files upon storage arrival.

### Step 2: SQLite Drift Schema Migration (Subagent Beta)
1. **Table Mappings:** Add `MediaAssetsTable` and `MediaTagsTable` class definitions in `client/lib/database/tables.dart`.
2. **SQLite Compilation:** Run code generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. **DAO Integration:** Define dynamic database queries delivering media items grouped by capture dates.

### Step 3: Flutter Presentation Grid UI (Subagent Beta)
1. **Everforest Colors:**
   - Scaffold canvas: `EverforestColors.bg0`.
   - Grid cards: `EverforestColors.bg1`.
   - Outline separators: 1px border lines in `EverforestColors.bg2`.
   - Text highlights: `EverforestColors.fg` (headers), `grey` (details).
2. **Grid View Widget:** Build list view loaders displaying image grids using thumbnails APIs.

### Step 4: AI Tagging Hook (Subagent Alpha)
1. **Automation Links:** Register classification logs inside sync managers:
   - Call `PhotoClassifier.analyzeImage(assetId)` upon file completions.
2. **Dirty Flags:** Mark mutated rows with `is_dirty = 1` to command immediate synchronization loops.
