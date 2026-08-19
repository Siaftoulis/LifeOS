---
id: "a1b2c3d4-0004-4a5b-9c0d-lifeosdeploy1"
type: "lifeos_deployment_ci_cd"
last_modified: 1784500000000
sync_status: "clean"
---

# LifeOS Deployment & CI/CD

> [!NOTE]
> **Home:** [[04 - LifeOS DevDocs/Home|Home]] | **Related:** [[04 - LifeOS DevDocs/INFRASTRUCTURE_CONTROL|Infrastructure Control]] · [[04 - LifeOS DevDocs/WEB_FAILSAFE|Web Failsafe]] · [[04 - LifeOS DevDocs/SECURITY_MODEL|Security Model]]

This document specifies the release pipeline and server deployment procedures for LifeOS as they exist in August 2026.

---

## 1. Versioning

| Artifact | Source of truth | Current value |
|---|---|---|
| Client build | `client/pubspec.yaml` | `1.5.0+2` |
| Release build number | `.agent/version.json` → `build_number` | `33` |
| Latest tagged release | git tag | `v1.4.0` |

- Tagging a release with `v*` triggers the pipeline. Release notes are generated from `.agent/version.json` metadata at publish time.
- `build_number` increments per release; the client version in `pubspec.yaml` is bumped manually per release cycle.

---

## 2. Release Pipeline (GitHub Actions)

Workflow: `.github/workflows/release.yml`, triggered on `v*` tags.

| Job | Runner | Produces |
|---|---|---|
| `build-android` | ubuntu-latest, Java 17 | `lifeos_client.apk` (release) |
| `build-windows` | ubuntu-latest | `lifeos_client-windows.zip` |
| `publish-release` | ubuntu-latest | GitHub Release with APK + ZIP attached |

### 2.1 Scaffold + Patch (both build jobs)

Because the CI runner cannot rely on the full monorepo client, both jobs regenerate a clean Flutter project and patch it:

1. `flutter create --project-name lifeos_client --org com.lifeos.app --platforms=android,windows`
2. Copy the actual `client/lib`, `client/assets`, and platform config from the monorepo over the scaffold.
3. **Restore `AndroidManifest.xml`** including the `LifeOSWidgetProvider` declaration (widget provider must survive the scaffold regeneration).
4. **Strip `gradle.properties` Java lines** that break CI Java toolchain resolution.
5. Build.

### 2.2 Android Build

- `flutter build apk --release` with Java 17 toolchain.
- Artifact: `lifeos_client.apk` (single universal APK).

### 2.3 Windows Build

- `flutter build windows --release`.
- Output zipped as `lifeos_client-windows.zip` (portable; no installer).

---

## 3. Publish Release

- `publish-release` depends on both build jobs.
- Release notes: `release_notes.md` produced from `.agent/version.json` (`build_number: 33` at the time of writing).
- Artifacts attached via `softprops/action-gh-release`: APK + ZIP.

---

## 4. Server Deployment (Production Box)

Deploy script: `deploy_server.ps1` (repo root), targeting the Linux production box **`pds-laptop-old`** over `tailscale ssh`.

### 4.1 Web Frontend

1. `flutter build web` from `client/`.
2. **Strip `flutter_service_worker.js`** from the build output (prevents stale SW caching, see [[04 - LifeOS DevDocs/SECURITY_MODEL|Security Model]]).
3. **Patch the bootstrap HTML** with a cache-buster (fingerprinted entry) so the browser always fetches fresh assets.

### 4.2 Backend Binaries

1. Cross-compile for linux/amd64 with `CGO_ENABLED=0`:
   - host daemon (serves `:50051` tailnet HTTP + `:50052` Funnel upstream)
   - sync relay (`server/`, port `:8080`)
2. Push over `tailscale ssh` to `root@pds-laptop-old`.
3. **MD5 checksum verification** of transferred binaries before activation.
4. Restart the systemd unit **`lifeos-host-daemon`**.

### 4.3 Resulting Prod Layout

| Service | Box | Port | Purpose |
|---|---|---|---|
| `lifeos-host-daemon` (systemd) | pds-laptop-old | 50051 | tailnet HTTP API |
| Funnel upstream | pds-laptop-old | 50052 | public web portal proxy target |
| sync relay | pds-laptop-old | 8080 | `/api/sync` + Yjs `/ws` relay |

---

## 5. Web-Only Deploy

- `client/deploy.ps1` performs a **web-only deploy** (Flutter web build → push → MD5 verify → restart/refresh) without rebuilding Go binaries.
- Used for frontend iterations when the backend is unchanged; skips the cross-compile step of `deploy_server.ps1`.

---

## 6. Deploy Checklist

1. Bump `build_number` in `.agent/version.json` and client version in `pubspec.yaml`.
2. Tag `vX.Y.Z` and push — watch `release.yml` jobs (android → windows → publish).
3. Download artifacts from GitHub Release; smoke-test APK on device.
4. For backend changes: run `deploy_server.ps1` (web + Go binaries + MD5 verify + systemd restart).
5. For web-only changes: run `client/deploy.ps1`.
6. Verify public portal at `https://lifeos-host.husky-forel.ts.net` and tailnet API on `:50051`.

---

## Related Documents

- [[04 - LifeOS DevDocs/SECURITY_MODEL|Security Model]]
- [[04 - LifeOS DevDocs/INFRASTRUCTURE_CONTROL|Infrastructure Control]]
- [[04 - LifeOS DevDocs/WEB_FAILSAFE|Web Failsafe]]
- [[04 - LifeOS DevDocs/BACKEND_ARCHITECTURE|Backend Architecture]]