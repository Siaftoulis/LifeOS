## LifeOS v1.5.29 (Build #67) — Soulseek P2P Lossless FLAC, Archive.org Direct FLAC & SoundCloud HQ Waterfall

Welcome to **LifeOS v1.5.29**! This update integrates deeper lossless audio networks directly into the Multi-Source Quality Waterfall:

---

### Highlights & What's New

#### 🌐 Soulseek (`slskd`) P2P Lossless FLAC Client
* **Native slskd Client**: Direct integration with the `slskd` REST API on `localhost:5030` or configured `SLSKD_URL`.
* **Automated Network Queries**: Issues automated peer queries for `Artist - Title flac` across the Soulseek P2P network.
* **Intelligent Peer Selection**: Prioritizes peers with free upload slots, highest bandwidth transfer speed, and uncompressed 16-bit/24-bit FLAC audio.
* **Automatic Peer Download Enqueueing**: Enqueues lossless tracks directly to the background downloader.

---

#### 🏛️ Archive.org Direct Lossless FLAC Stream Extractor
* **Direct File Metadata Inspection**: Upgraded Archive.org queries to parse item file tables at `archive.org/metadata/{id}/files`.
* **Direct Download URLs**: Extracts direct `https://archive.org/download/{id}/{filename.flac}` URLs instead of metadata pages.
* **Pristine Container Retention**: Audio files download directly without transcoding.

---

#### ☁️ SoundCloud HQ 320k Stream Discovery & Premium Hooks
* **SoundCloud HQ Discovery**: Seamless fallback to 320kbps streams via verified native search selectors.
* **Tidal & Deezer Credentials Support**: Built-in environment hooks (`TIDAL_TOKEN`, `DEEZER_ARL`) to enable master quality streams when credentials are provided.

---

### Verification & Performance
* **Automated Unit Tests**: 20/20 unit tests passed (`slskd_test.go`, `waterfall_test.go`, `innertube_test.go`, `stream_cache_test.go`, `enrichment_test.go`).
* **Offline Resilience**: Instant sub-800ms fallback when external daemons are offline.
