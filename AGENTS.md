# AGENTS.md

LifeOS — self-hosted, offline-first Flutter + Go monorepo (Windows client primary, Android, Web portal, Tailscale mesh). Read `.agent/AGENTS.md` too — it holds binding architecture rules (one daemon `/api/v1/<domain>`, local-first Drift, feedback-loop questions after building features).

## Layout & ownership

- `client/` — Flutter app (Android + Windows + Web). Entry: `lib/main.dart`. All Dart lives here.
- `backend/host-daemon/` — THE backend: single Go daemon, all `/api/v1/*` routes (≈34 modules), SQLite per domain, serves the Flutter web build at `/`. Listeners: tailnet `:50051`, funnel localhost `:50052`. Error-prone entry: `main.go` (auth-gate allowlist at ~line 202).
- `server/` — separate lightweight Go sync relay (`:8080`, only `/api/sync` + `/ws`). Not a domain API.
- `data/` — stale DB copies from an older layout; the daemon's live data is `backend/host-daemon/data/`.
- `vault/` — Obsidian docs (specs per module in `vault/02 - Technical Specs/<Module>/` — read these before extending a module).
- `appflowy_repo/`, `aves_repo/`, `native_yrs/` — vendored upstream repos. **Do not edit.** They are the sole source of pre-existing `flutter analyze` errors.
- `backend/newpipe-bridge/` — Java Gradle bridge (YouTube streams), at `127.0.0.1:18785`.

## Commands

- Flutter is pinned to **3.44.9** (scoop). Do not upgrade to 3.47+ — `appflowy_editor 1.5.2` breaks there.
- Drift codegen (after schema/DAO edits — generated files ARE committed, must be committed too):
  `dart run build_runner build --delete-conflicting-outputs` (in `client/`)
- Schema version is manual: `client/lib/database/database.dart` `schemaVersion` + `onUpgrade`.
- Analyze: `flutter analyze` shows ~1.8k pre-existing issues; filter — errors outside `appflowy_repo/` are the real signal.
- Go: `go build .` / `go test ./...` in `backend/host-daemon`; cross-compile with `GOOS=linux GOARCH=amd64 CGO_ENABLED=0`.

## Deploy to server (pds-laptop-old)

- `deploy_server.ps1` builds web, patches `flutter_bootstrap.js` (service worker removal + `?t=` cache buster), ships via `tailscale ssh root@pds-laptop-old` to `/var/lib/lifeos-host-daemon`, restarts systemd `lifeos-host-daemon`.
- **Gotcha:** `flutter build web` prints "Wasm dry run findings" to stderr → PowerShell `$ErrorActionPreference="Stop"` aborts the script. Run `flutter build web --release` first, then `deploy_server.ps1 -SkipBuild`.
- **Gotcha:** `tailscale ssh` requires interactive human approval — it prints `To authenticate, visit: https://login.tailscale.com/a/...` and hangs. The user must open the URL before any deploy works.

## Release (GitHub Actions)

- Workflow `.github/workflows/release.yml` triggers on any `v*` tag: builds Android APK + Windows ZIP, publishes release with body from `.agent/version.json` `build_number`.
- Bump both: `client/pubspec.yaml` `version:` and `.agent/version.json`, commit, then `git tag vX.Y.Z` + push tag.
- **Gotcha:** workflow MUST keep `flutter-version: '3.44.9'` pinned in `subosito/flutter-action` (both jobs) — unpinned stable is 3.47 which breaks the build.
- **Gotcha:** never re-add `flutter create`/`flutter pub add` steps to the workflow — re-resolving deps on the runner breaks the build. `android/`, `windows/`, `pubspec.lock` are committed; runners only `flutter pub get`.
- **Gotcha:** `client/android/gradle/wrapper/gradle-wrapper.jar` is git-ignored by `client/android/.gitignore` but must stay tracked (was force-added) or runner builds fail.
- After a failed release: fix, push, delete+recreate the tag (`git push origin --delete vX.Y.Z`), re-push. `gh run list` may lag a few seconds after tag push.

## Music module specifics

- Backend: `backend/host-daemon/internal/music/` (tracks/search/download/ytstream/lyrics in `media.db`, `data/media/music/<artist>/<title> [id].mp3`, stream cache `data/music_cache/<id>.mp4` with HTTP 206 + CORS).
- Client: `client/lib/presentation/widgets/media_hub/music_library/`; repository `MusicRepository` in `client/lib/core/domain_repositories.dart` (multi-repo file — keep adding features there or its siblings).
- DSP: `client/lib/core/audio_dsp_service.dart` — Windows applies `af` filter string via libmpv FFI on all live mpv handles (`audio_dsp_native.dart`, Windows-only; hacks media_kit internal temp-file handle registry — fail silently, keep it defensive). Android uses `AndroidEqualizer` from just_audio.
- Offline device downloads: Drift table `OfflineMusicTracks` + files in `getApplicationDocumentsDirectory()/music_offline/`; platform split via conditional export pattern (`offline_music_download.dart` → `_io.dart` / `_web.dart`).
- **Gotcha:** importing `database/database.dart` into any file using domain `MusicTrack` requires `hide MusicTrack` (Drift generates a same-named class).
- **Product decision (2026-08):** music must NOT play in the web portal — web shows UI + downloaded items only. Playback (and offline play-from-file, EQ, DSP) is native apps only (Windows/Linux/macOS/Android/iOS). Don't build web audio paths.

## Other gotchas

- `vault/` files get touched by background watchers/sync agents constantly — inspect `git status` and stage only intended files when committing.
- API auth: every `/api/*` path needs JWT except the public allowlist in `main.go` (currently includes ALL `/api/v1/music/*` — unauthenticated by design, keep in mind, don't silently break the web portal's no-auth music embeds).
- Client connects to the daemon over `daemonUrl` (local discovery list in `client/lib/api_client.dart`); on web it's same-origin.