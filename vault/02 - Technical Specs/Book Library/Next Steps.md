# Next Steps | Book Library

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Book Library|Book Library]]

## 1. Backend Implementation (Beyond Stubs)
- **EPUB/PDF Processing:** Implement actual EPUB metadata extraction in Go (using an epub parsing library) to extract Title, Author, Cover Image, and Chapter list.
- **Audiobook Chunking:** Replace the stub audio player with real `Accept-Ranges` streaming via the Go HTTP server to support fast-forwarding large MP3/M4B files.
- **Highlight Extraction:** Implement a parser for Kindle `My Clippings.txt` to sync highlights into the local database.

## 2. Data Interconnectivity & Relationships
- **Link to Knowledge Base:** Highlights from books should automatically generate Linked Markdown notes in the Obsidian Vault (`06 - Journal & Tracking/Highlights/`).
- **Link to Point Star System:** Finishing a book or listening to 1 hour of an audiobook should yield points (e.g., `+5 Star Points`).

## 3. Open Design Questions
1. Do we need an OPDS server (like Calibre-Web) to sync reading progress with dedicated e-ink readers, or will reading happen exclusively within the LifeOS Flutter app?
2. Should we integrate a text-to-speech (TTS) local engine to read EPUB files aloud?
