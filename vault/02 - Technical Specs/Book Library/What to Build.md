# What to Build | Book Library

This document specifies the exact SQLite schemas, JSON-RPC/REST API paths, and Flutter widget components to build for the Book Library system.

---

## 1. Database Architecture (SQLite / Drift)

Four tables must be defined in the SQLite storage layer to support text files, audio file metadata, progress tracking, and annotations.

```sql
-- Schema for Books metadata
CREATE TABLE IF NOT EXISTS books (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    author TEXT,
    current_page INTEGER DEFAULT 0,
    total_pages INTEGER DEFAULT 0,
    file_path TEXT NOT NULL,
    updated_at INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0
);

-- Schema for Audiobooks metadata
CREATE TABLE IF NOT EXISTS audiobooks (
    id TEXT PRIMARY KEY,
    book_id TEXT NOT NULL,
    file_path TEXT NOT NULL,
    duration_seconds INTEGER DEFAULT 0,
    current_seconds INTEGER DEFAULT 0,
    updated_at INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0,
    FOREIGN KEY(book_id) REFERENCES books(id) ON DELETE CASCADE
);

-- Schema for Progress Bookmark tracking
CREATE TABLE IF NOT EXISTS reading_progress (
    book_id TEXT PRIMARY KEY,
    page INTEGER DEFAULT 0,
    seconds INTEGER DEFAULT 0,
    updated_at INTEGER NOT NULL,
    synced_at INTEGER,
    FOREIGN KEY(book_id) REFERENCES books(id) ON DELETE CASCADE
);

-- Schema for Book Annotations and Highlights
CREATE TABLE IF NOT EXISTS book_highlights (
    id TEXT PRIMARY KEY,
    book_id TEXT NOT NULL,
    text_content TEXT NOT NULL,
    note_content TEXT,
    page_number INTEGER,
    created_at INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0,
    FOREIGN KEY(book_id) REFERENCES books(id) ON DELETE CASCADE
);
```

---

## 2. API Specifications (Go Backend Daemon)

The host daemon manages media streaming, file retrieval, and Kindle compilation over the secure Tailscale network loop.

### REST Endpoints
- **List & Sync Metadata:**
  - `GET /api/v1/books`
  - Response: `JSON` list of books, audiobooks, progress trackers, and sync metadata status.
- **Audiobook Byte-Range Streamer:**
  - `GET /api/v1/books/stream?id={audiobook_id}`
  - Headers: Supports `Range: bytes=X-Y`.
  - Response: Binary audio chunk stream.
- **Kindle Web Portal Reader:**
  - `GET /api/v1/books/kindle`
  - Parameters: `book_id` (optional, displays shelf index if empty), `page` (optional page display).
  - Response: High-contrast, clean HTML formatting with "Next Page" and "Previous Page" hyperlink anchors.

---

## 3. UI Component Registry (Flutter Client)

All widgets are declared inside `client/lib/presentation/widgets/` or plugins:

- **`BookLibraryDashboard`:** Main module screen. Renders a bookshelf style list layout displaying covers (or text blocks) and current progress bars.
- **`EPUBReaderScreen`:** Custom text-rendering view displaying formatted chapters, page layout calculations, and a tap gesture highlight creator.
- **`AudioPlayerWidget`:** Bottom sheet overlay or sidebar utility presenting playback status, a slide-seek bar, sleep timer controls, and watch companion synchronization.
- **`HighlightCurtain`:** Pop-up dialog allowing the user to view annotations, edit brief text commentary, and push to the Obsidian Zen Editor layout.
- **`EinkReaderView`:** High-contrast alternate client mode optimized for minimal frame rates and e-paper displays.
