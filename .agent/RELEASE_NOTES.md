## LifeOS v1.5.19 (Build #57) — Display-Adaptive Visualizers, Desktop DSP Filter Engine & Seamless Lyrics Navigation

Welcome to **LifeOS v1.5.19**! This update delivers high-refresh-rate adaptive visualizers (60Hz / 120Hz / 144Hz+), native libmpv DSP equalizer filter injection on Desktop, elimination of lyrics navigation dead zones, and resolved YouTube Music online search timeouts.

---

### Highlights & What's New

#### 🌊 Display-Adaptive Spectrogram Visualizers (60Hz / 120Hz / 144Hz+)
* **Continuous Vsync-Driven Clock**: Decoupled visualizer calculations from the 200ms audio position intervals, driving all animations via a continuous vsync animation ticker for liquid-smooth performance.
* **Delta-Time (`dt`) Peak Cap Kinematics**: Converted floating peak cap gravity to delta-time kinematics (`gravity * dt`). Peak caps now drop at the exact physical speed across 60Hz, 90Hz, 120Hz, 144Hz, and 240Hz monitors.
* **Silky Smooth Multi-Mode Styles**: **BARS**, **BEAM** (fluorescent oscilloscope), **HALO** (cyber radial rays), and **VU** (analog twin needles) now animate with zero judder.

---

#### 🎛️ Desktop Native libmpv DSP Audio Filter Injection
* **Direct Player Filter Hook**: Implemented `LifeOSJustAudioMediaKit` and `LifeOSMediaKitPlayer` platform plugin, directly registering active `media_kit` players.
* **Real-Time EQ & Tone Alteration**: Replaced the debug-only temp file lookup with direct `(player.platform as NativePlayer).setProperty('af', filterString)`.
* **Immediate Acoustic Feedback**: Adjusting the 10-Band EQ sliders, Bass boost, Treble sparkle, Preamp gain, and Reverb knobs immediately sculpts the audio output in real time on Windows and Linux.

---

#### 🎤 Seamless Lyrics & Artwork Navigation (Zero Dead Zones)
* **Fluid Sheet Dismissal**: Restored downward swipe gestures (`primaryVelocity > 200`) so swiping down on the hero deck dismisses the Now Playing sheet from any mode (including lyrics).
* **Dual Glass Quick-Switch Pills**: Added sleek floating pills at the top of the lyrics view: `[ 💿 Artwork ]` on the left and `[ ♫ Spectrum ]` on the right for instant 1-tap mode toggling.
* **Tap Outside to Return**: Tapping the card outside of active lyric text lines smoothly cycles back to Artwork.

---

#### 🔍 YouTube Music Online Search Fix
* **Eliminated 5-Second Search Timeout**: Upgraded search execution to `ApiClient.instance.getDaemonSlow` so `yt-dlp` queries (such as "Bubblegum Bitch" and heavy remixes) complete reliably without getting dropped.
* **Dedicated "YouTube Music Online" Section**: Prominently displays online search results with stream badges, instant 1-tap playback, and direct download to the local library.
* **New Category Pill**: Added a dedicated `YouTube Music` filter pill to the category carousel in the Poweramp search screen.

---

#### 📐 Spatial UI HUD Clean-Up
* **Dock Overlap Removed**: Removed the `[ x , y ]` coordinate chevron indicator widget from the bottom of the screen to ensure zero visual overlap with the Poweramp bottom navigation dock.

---

### Verification & Performance
* **Zero Lint Errors**: Passed `flutter analyze` with 0 issues.
* **Automated Unit Tests**: 16/16 unit and audio DSP tests passed (`poweramp_dsp_and_metadata_test.dart`, `music_controls_p0_test.dart`).
