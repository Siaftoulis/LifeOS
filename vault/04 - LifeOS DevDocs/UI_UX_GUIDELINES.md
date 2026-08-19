---
id: "a1b2c3d4-0003-4a5b-9c0d-lifeosuiux01"
type: "lifeos_ui_ux_guidelines"
last_modified: 1784500000000
sync_status: "clean"
---

# LifeOS UI/UX Guidelines

> [!NOTE]
> **Home:** [[04 - LifeOS DevDocs/Home|Home]] | **Related:** [[04 - LifeOS DevDocs/STATE_MANAGEMENT|State Management]] · [[04 - LifeOS DevDocs/Aves_Local_AI_Tagging|Aves Local AI Tagging]]

This document defines the visual and interaction language for all LifeOS surfaces (Flutter client on Android/Windows/Web) as they exist in August 2026.

---

## 1. Design Principles

1. **Minimalist flat-line design**: no gradients, no shadows, no skeuomorphism; thin lines and flat fills only.
2. **Calm and legible**: muted, low-contrast palette; content density over decoration.
3. **Spatial by default**: the app is a 2D space you move through, not a tab hierarchy (see Section 4).
4. **Reference-quality clones**: signature modules replicate proven UIs 1:1 (Poweramp v3 music, Aves gallery, AppFlowy-based zen editor).
5. **No emojis, ever**: icons are line glyphs; documentation and UI copy avoid emoji characters entirely.

---

## 2. Color & Typography

### 2.1 Palette — Everforest

The palette is defined in `client/lib/theme/everforest_colors.dart` and is the single source of color tokens.

| Token | Value | Usage |
|---|---|---|
| Dark background | `#09090B` | base surface (all screens) |
| Background alt | Everforest `bg0`-family | cards, panels, HUD |
| Foreground | Everforest `fg`-family | primary text |
| Accent | Everforest `aqua`/`green`-family | highlights, focus, positive states |
| Caution | Everforest `red`/`orange`-family | negative balances, penalties, errors |
| Gold | Everforest gold tint | zen editor highlights (see 5.3) |

> [!NOTE]
> Web and native must pull tokens from `everforest_colors.dart` only. Hardcoded hex values are not permitted in new widgets.

### 2.2 Typography

- **JetBrains Mono** is the display/mono typeface across the client (HUD coordinates, terminal-ish surfaces, code-like data).
- Default Flutter text rendering for body copy, sizes per Material scale; no decorative fonts.
- The HUD coordinate readout (`[x,y]`) is always JetBrains Mono at a fixed size.

---

## 3. Layout & Navigation

### 3.1 Spatial Home Grid

- The home screen is a **2D matrix grid of modules** (spatial engine, `SpatialEngineScaffold`).
- Each cell is a module entry (flat-line icon + label); modules are placed on fixed grid coordinates.
- A **HUD** overlays the grid showing the current `[x,y]` coordinates, points/stars balance, and active session info.

### 3.2 Input & Motion

| Gesture | Action |
|---|---|
| Arrow keys | move cursor one cell |
| Double-bump at edge | pan to neighboring screen |
| Escape | pop navigation back-stack |
| Tap/enter | open focused module |

- Transitions: **350ms `easeOutCubic`** between cells and screens — snappy start, soft settle.
- Idle cells are wrapped in `RepaintBoundary`; moving the cursor never repaints the whole grid.

### 3.3 Modality

- Full-screen module views replace the grid (back via Escape or system back).
- Dialogs and bottom sheets are reserved for confirmations and pickers; inline editing is preferred.

---

## 4. Signature Module Styles

### 4.1 Music Player (Poweramp v3-style)

- Album-art-centric now-playing view, mirroring Poweramp v3's layout: large art, centered transport controls, swipeable track list.
- Flat-line progress bar; JetBrains Mono timestamps.
- Backend: `music` domain streams via m4a proxy (`/api/v1/music/*`) with byte-range + CORS; lyrics from LRCLIB.

### 4.2 Gallery (Aves 1:1 replica)

- Three-column thumbnail grid with fast fling scrolling and pinched zoom into full-screen viewer, matching the Aves app layout and gesture behavior.
- Deduplication indicators from `gallery` domain (sha256/dHash); dominant-color chips shown in the viewer info panel.
- Files organized on disk as `data/gallery/<user>/<year>/<month>`.

### 4.3 Zen Editor (AppFlowy-based)

- Structured block editor derived from AppFlowy's editing model.
- Styling: **bold** and **gold highlight** markups are the two emphasis styles; no other inline formatting is exposed in the toolbar.
- Zen content syncs through the `zen` domain (DB-backed fs CRUD, LWW with tombstones); web has no local disk — the backend is the store.

---

## 5. Content & Documentation Style

1. **Vault docs**: Obsidian-style wiki links `[[...]]` for cross-references; `> [!NOTE]` callouts for asides; single `#` title; `##` sections; markdown tables for structured facts.
2. **No emojis** anywhere in docs, UI strings, or commit messages.
3. **Factual and specific**: docs cite file paths, endpoints, and ports rather than prose summaries.
4. **YAML frontmatter** on vault docs: `id`, `type`, `last_modified` (unix ms), `sync_status`.

---

## 6. State & Data Display Conventions

| Surface | Convention |
|---|---|
| Points balance | stars display (1 star = 100 points); live via `points:balance-change` events |
| Sync status | silent background sync; only failures surface (subtle toast), never progress bars |
| Offline | Local Mode banner when daemon unreachable; UI stays fully functional |
| Errors | inline text in caution color; no dialog spam |
| Loading | flat-line spinners; skeletons discouraged (fast local reads) |

---

## 7. Accessibility & Platform Notes

- Keyboard-first on Windows/web (arrow navigation, Escape, enter); touch on Android (tap = enter, swipe on grids).
- Contrast: Everforest tokens chosen to meet readable contrast on `#09090B`; avoid pure white text on dark surfaces.
- Android launcher grid and folder views follow the same flat-line grid language; point-gated apps show a star cost badge (see [[04 - LifeOS DevDocs/RPG_PLAYER_CARD_SYSTEM|RPG Player Card System]]).

---

## Related Documents

- [[04 - LifeOS DevDocs/STATE_MANAGEMENT|State Management]]
- [[04 - LifeOS DevDocs/Aves_Local_AI_Tagging|Aves Local AI Tagging]]
- [[04 - LifeOS DevDocs/RPG_PLAYER_CARD_SYSTEM|RPG Player Card System]]
- [[04 - LifeOS DevDocs/Home|Home]]