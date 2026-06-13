# Next Steps | YouTube Client

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/YouTube Client|YouTube Client]]

## 1. Backend Implementation (Beyond Stubs)
- **yt-dlp Native Integration:** The Go Daemon must execute the local `yt-dlp` binary with specific flags (`-f best`, `--write-thumbnail`) to fetch videos and save them to the local NAS.
- **Active Cron Lockout:** Implement a Go `ticker` (e.g., running every 1 minute) that actively checks if a YouTube session is active. If the user runs out of Star Points, the ticker forcefully kills the `mpv` player or blocks network access.

## 2. Data Interconnectivity & Relationships
- **Link to Point Star System:** Actively drains points (-10 per 30 mins). This creates the ultimate friction against mindless scrolling.
- **Link to Movie/Music Library:** Downloaded YouTube videos might optionally be pushed into the Music Library (if audio-only) or Movie Library.

## 3. Open Design Questions
1. How should we prevent the user from just opening YouTube in a normal browser? Should the Go Daemon alter the OS `hosts` file to block youtube.com system-wide unless the LifeOS session is active?
2. Do you want the YouTube client to support pulling full playlists, or just single videos?
