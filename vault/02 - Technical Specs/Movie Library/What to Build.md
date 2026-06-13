# What to Build | Movie Library

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Movie Library|Movie Library]]



This document specifies the exact SQLite schemas, REST API paths, and Flutter widget components to build for the Movie Library media catalog.

---

## 1. Database Architecture (SQLite / Drift)

Three tables must be defined in the SQLite cache layer to support media metadata, watchlists, and personal logs.

```sql
-- Schema for Movies Metadata Catalog
CREATE TABLE IF NOT EXISTS movies (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    imdb_id TEXT,
    cover_path TEXT,
    file_path TEXT NOT NULL,
    status TEXT NOT NULL, -- 'AVAILABLE', 'DOWNLOADING', 'WATCHED'
    updated_at INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0
);

-- Schema for Watchlist Queues
CREATE TABLE IF NOT EXISTS movie_watchlist (
    id TEXT PRIMARY KEY,
    movie_id TEXT NOT NULL,
    added_at INTEGER NOT NULL,
    priority INTEGER DEFAULT 0,
    is_dirty INTEGER DEFAULT 0,
    FOREIGN KEY(movie_id) REFERENCES movies(id) ON DELETE CASCADE
);

-- Schema for Personal Movie Reviews
CREATE TABLE IF NOT EXISTS movie_reviews (
    id TEXT PRIMARY KEY,
    movie_id TEXT NOT NULL,
    rating REAL DEFAULT 0.0,
    comment TEXT,
    is_dirty INTEGER DEFAULT 0,
    FOREIGN KEY(movie_id) REFERENCES movies(id) ON DELETE CASCADE
);
```

---

## 2. API Specifications (Go Backend Daemon)

The host daemon manages downloader pipelines, queries TMDb APIs, and downloads subtitle logs.

### REST Endpoints
- **List & Control Catalog:**
  - `GET /api/v1/movies`
  - Response: `JSON` list of local files, TMDb ratings, and watch logs.
- **Add Watchlist Targets:**
  - `POST /api/v1/movies/watchlist`
  - Payload: `{"movie_id": "imdb_code_string"}`
  - Response: Added watchlist metadata details.
- **Get OpenSubtitles Lists:**
  - `GET /api/v1/movies/subtitles?imdb_id={id}`
  - Response: Matching subtitles files list.

---

## 3. UI Component Registry (Flutter Client)

All widgets are declared inside `client/lib/presentation/widgets/` or plugins:

- **`MovieLibraryDashboard`:** Main screen presenting catalog cards, search fields, and watchlist status indicators.
- **`VLCPlayerScreen`:** Integrated native player rendering high-quality streams, volume sliders, and subtitle selectors.
- **`MovieReviewEditor`:** Editor view prompting reviews input, ratings selectors, and notes export keys.
