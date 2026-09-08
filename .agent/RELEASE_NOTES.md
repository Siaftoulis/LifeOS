## LifeOS v1.5.30 (Build #68) — Lossless Sources Configuration UI & Soulseek / Tidal / Deezer Settings

Welcome to **LifeOS v1.5.30**! This release introduces a comprehensive settings interface and backend configuration subsystem for managing lossless audio sources, Soulseek P2P connections, and HiFi credentials.

---

### Highlights & What's New

#### 🎛️ Lossless Sources & Integrations UI Modal
* **Dedicated Configuration Interface**: Accessible directly from **Poweramp Settings** (`Lossless Sources & Integrations`) and the **Download Quality Sheet** (`Configure Sources` header button).
* **Soulseek (`slskd`) Management**:
  * Toggle switch to enable/disable Soulseek network querying.
  * Custom `slskd` daemon URL configuration (defaulting to `http://localhost:5030`).
  * API key authorization input for secured `slskd` setups.
  * Live **"Test Soulseek Connection"** button with instant visual connection status badge (`Connected` vs `Offline`).
* **Tidal HiFi Credentials**:
  * Input field for Tidal token / Client ID to unlock master quality FLAC streams.
* **Deezer HiFi Credentials**:
  * Input field for Deezer ARL cookie to enable 1411kbps lossless FLAC streaming.

---

#### 💾 Persistent Music Engine Configuration
* **Database Persistence**: Introduced `music_config` table in `media.db` for reliable, cross-restart storage of all audio provider credentials.
* **Dedicated Backend Endpoints**:
  * `GET /api/v1/music/config` — Retrieves current integration configuration with sensible defaults.
  * `POST /api/v1/music/config` — Updates and persists provider settings.
  * `POST /api/v1/music/config/test-slskd` — Tests daemon connectivity and reports active status.

---

### Verification & Performance
* **Automated Unit Tests**: All 20 backend music tests passed (`slskd_test.go`, `waterfall_test.go`, etc.).
* **Zero Client Lint Errors**: Clean Flutter analysis across all newly created and updated UI components.
