# Next Steps | Movie Library

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Movie Library|Movie Library]]

## 1. Backend Implementation (Beyond Stubs)
- **Local Video Streaming:** The Go Daemon must implement `Accept-Ranges: bytes` natively to serve large `.mkv` and `.mp4` files from the local NAS directly to the Flutter video player without buffering the whole file in RAM.
- **Metadata Scraping:** Implement a local scraper (e.g., fetching from TMDB) that caches posters and plots locally when a new file is detected, so the UI remains offline-capable.

## 2. Data Interconnectivity & Relationships
- **Link to Point Star System:** Writing detailed `MovieReviews` after watching a film rewards `+5 Star Points`.
- **Link to Home Management:** Starting a movie should trigger a webhook to dim the living room lights via the IoT module.

## 3. Open Design Questions
1. Do you want to integrate a local Plex/Jellyfin instance and just have LifeOS act as a frontend, or should LifeOS handle the raw video files entirely itself?
2. How should subtitles (`.srt`) be handled over the Tailscale mesh?
