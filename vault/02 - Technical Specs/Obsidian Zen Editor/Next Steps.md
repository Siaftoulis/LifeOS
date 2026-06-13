# Next Steps | Obsidian Zen Editor

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Obsidian Zen Editor|Obsidian Zen Editor]]

## 1. Backend Implementation (Beyond Stubs)
- **Atomic Markdown Sync:** The `/api/markdown/sync` endpoint must use strict file locking (`sync.Mutex` in Go) to prevent corruption when multiple Tailscale nodes try to write to the same `.md` file simultaneously.
- **Bidirectional LWW Sync:** Implement block-level or file-level Sequence-Delta CRDTs to merge changes if you edit a file on mobile while offline, and then reconnect to the host daemon.

## 2. Data Interconnectivity & Relationships
- **Link to Point Star System:** Active typing/editing in the Zen Editor for 1 continuous hour awards `+5 Star Points`.
- **Link to CHTM & Fast Capture:** Quick notes captured from the Home Screen or Task Manager must be automatically appended to the Daily Note in Obsidian.

## 3. Open Design Questions
1. Do we want to implement true collaborative editing (like Google Docs) using WebSockets and Operational Transformation (OT), or is LWW file-overwriting sufficient for a single-user system?
2. How should file attachments (images pasted into the editor) be routed to the local Vault?
