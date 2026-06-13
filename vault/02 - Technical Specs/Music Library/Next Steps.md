# Next Steps | Music Library

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Music Library|Music Library]]

## 1. Backend Implementation (Beyond Stubs)
- **Local Audio Streaming:** Similar to movies, the Go Daemon must serve audio chunks.
- **Metadata Extraction:** Use an ID3 tag parser in Go to automatically extract Artist, Album, and Cover Art embedded directly in the `.flac` or `.mp3` files, eliminating the need for cloud databases.

## 2. Data Interconnectivity & Relationships
- **Link to Point Star System:** Completing foreign language lyric translations inside the music player yields `+2 Star Points`.
- **Link to Knowledge Base:** Favorite lyrics could be exported as Markdown notes into the Obsidian vault.

## 3. Open Design Questions
1. Should the Music Library support background playing on mobile (requiring native Android OS service integration), or is it mostly for desktop listening?
2. Do we need an automated lyrics scraper, or will you embed lyrics directly into the audio files?
