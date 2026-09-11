## LifeOS v1.6.1 (Build #81) — Offline & Local Track Radio, Pure-Dart Metadata & Dynamic Smart Playlists

Welcome to **LifeOS v1.6.1**! This release brings intelligent radio recommendations to local and offline music, pure-Dart audio tag parsing with embedded cover art caching, and high-performance dynamic Smart Playlists.

---

### Highlights & New Features

#### 📻 Offline & Local Track Radio
* **Local Radio Everywhere**: You can now start an infinite Track Radio directly from any local file or offline track (`local_<hash>`).
* **Hybrid Fallback Engine**:
  * **Online**: Resolves local song metadata (artist, title, genre) from SQLite and seeds YouTube Music algorithmic radio.
  * **Offline**: Seamlessly activates Drift's local recommendation scoring algorithm (+3 artist match, +2 genre match, weighted by play count) with automatic library backfill.
* **Direct Path Preservation**: The playback queue preserves direct local disk paths (`r.filePath`), guaranteeing uninterrupted native offline playback without broken network streaming URLs.
* **One-Tap Offline Radio**: Added a quick "Start Offline Radio" button directly in the Offline Music Vault header.

#### 🎨 Pure-Dart Audio Metadata & Embedded Album Art
* High-performance, zero-native-dependency tag reader for ID3v1, ID3v2.2-2.4 (`TIT2`, `TPE1`, `TALB`, `TYER`, `TCON`, `APIC`), MP4/M4A atoms (`©nam`, `©ART`, `©alb`, `covr`), and FLAC Vorbis/Picture blocks.
* Caches extracted album covers to disk and renders via the universal `MusicCoverArt` component.

#### 🎛️ Dynamic Smart Playlists
* Create and run dynamic smart playlists powered by local metadata rules (Genre, Decade, Folder, Recently Added, Most Played) with one-tap preset mix carousels.
