---
id: "a1b2c3d4-0001-4a5b-9c0d-lifeossec01"
type: "lifeos_security_model"
last_modified: 1784500000000
sync_status: "clean"
---

# LifeOS Security Model

> [!NOTE]
> **Home:** [[04 - LifeOS DevDocs/Home|Home]] | **Related:** [[04 - LifeOS DevDocs/WEB_FAILSAFE|Web Failsafe]] · [[04 - LifeOS DevDocs/EMBEDDED_NETWORK|Embedded Network]] · [[04 - LifeOS DevDocs/INFRASTRUCTURE_CONTROL|Infrastructure Control]] · [[04 - LifeOS DevDocs/BACKEND_ARCHITECTURE|Backend Architecture]] · [[04 - LifeOS DevDocs/DEPLOYMENT_CI_CD|Deployment & CI/CD]]

This document is the authoritative security specification for the LifeOS platform as it exists in August 2026. It covers transport, authentication, authorization, secret handling, web exposure, deploy integrity, and the sync relay's access model.

---

## 1. Threat Model & Principles

The system assumes an attacker who may have:

- Direct network access to the host (LAN or compromised peer on the tailnet).
- Public internet access to anything exposed via Tailscale Funnel.
- Knowledge of endpoint paths and the API surface.

Guiding principles applied across the stack:

1. **Encryption in transit end to end**: all mesh traffic is WireGuard-encrypted via the embedded Tailscale node; the only public surface is the Funnel-exposed web portal.
2. **Minimal public surface**: Funnel exposes only the web portal; daemon and relay APIs never listen on public interfaces.
3. **Explicit allowlists**: everything behind the global JWT gate unless explicitly whitelisted as public.
4. **Backend-only secrets**: external API keys live in environment variables on the backend only; the client never holds them.
5. **No secrets in the repository**: `data/` is gitignored; users, keys, and runtime state are never committed.

---

## 2. Network Transport

### 2.1 Tailnet (WireGuard)

- The host daemon embeds Tailscale via `tsnet` (see [[04 - LifeOS DevDocs/EMBEDDED_NETWORK|Embedded Network]]), joining as node `lifeos-host` under tailnet `husky-forel.ts.net`.
- All tailnet traffic is WireGuard end-to-end encrypted (curve25519 key exchange, ChaCha20-Poly1305 payloads).
- `tailnet.go` performs `WhoIs` on incoming connections to resolve `X-Tailnet-User` identity headers for the web proxy layer.

### 2.2 Funnel Public Exposure

| Item | Value |
|---|---|
| Public URL | `https://lifeos-host.husky-forel.ts.net` |
| Inbound | Tailscale Funnel (TCP 443) |
| Target | Proxy to `127.0.0.1:50052` (Funnel upstream) |
| Mesh API | `:50051` tailnet HTTP (never public) |
| Relay | `:8080` on the prod box (sync + Yjs relay, tailnet-only) |

> [!NOTE]
> Funnel terminates at the web portal only. No daemon API route is reachable from the public internet except through the authenticated web portal.

---

## 3. Authentication

### 3.1 Global JWT Gate

- Implemented in `backend/host-daemon/internal/auth/middleware/jwt.go`.
- HS256-signed JWTs with a 24-hour expiry.
- Key resolution order: `JWT_SECRET` environment variable → persisted secret file `data/jwt_secret` → randomly generated fallback (persisted on first run).
- Every daemon route passes through the gate unless listed in the public allowlist.

### 3.2 Public Allowlist

The following routes bypass the JWT gate explicitly:

| Route | Reason |
|---|---|
| `POST /login`, `POST /register` | credential entry |
| `oauth providers/start`, `oauth providers/callback` | SSO handshake |
| `/api/markdown/collab` | Yjs collaboration websocket |
| `/api/v1/events` | event stream websocket (token-authenticated) |
| `/api/v1/radar/live` | location live feed |
| `/api/v1/music/*` | public music route group (proxy streaming) |

- The `publicOnly` handler **denies** `register` and `login` when the request arrives over the Funnel path, enforcing **invite-only registration** on the public web portal.

### 3.3 Password Authentication

- Passwords hashed with bcrypt (cost factor per `internal/auth` defaults).
- SQLite user store (`data/users.db` domain module) seeds the initial admin user `panospds` with a bcrypt hash.
- Per-IP brute-force limiter: **5 failed attempts per 5 minutes** per source IP.
- Roles: `ADMIN`, `USER` (NORMAL), `CHILD` — enforced at route level via role interceptors (see Child Lock in [[04 - LifeOS DevDocs/BACKEND_ARCHITECTURE|Backend Architecture]]).

### 3.4 OAuth SSO

- `backend/host-daemon/internal/oauth` implements SSO:
  - GitHub: `read:user` scope.
  - Google: `openid email profile` scopes.
- CSRF protection: OAuth `state` cookie with a 10-minute expiry, validated on callback.
- Identity mapping persisted in `data/oauth_users.json` (external provider → LifeOS user).
- On web, the OAuth callback writes the JWT into `localStorage('lifeos_token')` for subsequent API calls.

### 3.5 Local Mode

- When the daemon is unreachable, the client falls back to an offline **ADMIN "Local Mode" session** (see [[04 - LifeOS DevDocs/STATE_MANAGEMENT|State Management]]) so the device remains usable without network; re-authentication is required once connectivity returns.

---

## 4. Authorization

| Role | Capabilities |
|---|---|
| `ADMIN` | Everything, including settings, user management, infra actions |
| `USER` | All domain features; no admin console |
| `CHILD` | Domain features with point gating; **settings locked** |

- **Child Lock**: a CHILD-role interceptor (in the `system` domain) rejects settings access for CHILD sessions at the route layer.
- Point-gated actions (app launch costs, YouTube sessions) are enforced server-side in the `points` domain (`apps/deduct`, session costs).

---

## 5. Credentials & Secrets Management

| Secret | Location | Notes |
|---|---|---|
| `JWT_SECRET` | env → `data/jwt_secret` → random fallback | HS256 signing key, persisted after first boot |
| `HMAC_SECRET` | env (backend only) | used by `crypto/hmac.go` to sign infrastructure actions |
| `TMDB_API_KEY` | env (backend only) | movies enrichment |
| `GITHUB_OAUTH_CLIENT_ID/SECRET`, `GOOGLE_OAUTH_CLIENT_ID/SECRET` | env (backend only) | SSO |
| DDNS credentials | env (backend only) | dynamic DNS |
| `LLM_BASE_URL` / `LLM_API_KEY` | env (backend only) | default `http://localhost:11434/v1` (Ollama, `llama3.2`) |
| OAuth user mapping | `data/oauth_users.json` | gitignored |

- `data/` is gitignored: user databases, secrets, keys, and runtime state are never committed to the repository.
- The client stores its JWT in memory; remember-me uses `flutter_secure_storage` (Android Keystore / platform secure storage). Web persists to `localStorage('lifeos_token')` only for the web portal.

---

## 6. Web Portal Hardening

- The daemon serves the Flutter web build at `/` via `http.FileServer(http.Dir("./web"))` with **no-cache headers**.
- The service worker (`flutter_service_worker.js`) is **stripped/purged** at deploy time so stale client code cannot be served from cache.
- Public Funnel entry proxies to `127.0.0.1:50052`; `X-Tailnet-User` identity from `WhoIs` is available to the proxy layer.

---

## 7. Deploy Integrity

- `deploy_server.ps1` cross-compiles daemon and relay binaries (`CGO_ENABLED=0`) and pushes them to the prod box `pds-laptop-old` over `tailscale ssh`.
- The push is verified with an **MD5 checksum comparison** before the systemd service (`lifeos-host-daemon`) is restarted.
- Releases attach APK/ZIP artifacts to GitHub Releases (see [[04 - LifeOS DevDocs/DEPLOYMENT_CI_CD|Deployment & CI/CD]]).

---

## 8. Sync Relay Access Control

- The relay (`server/`, port 8080) accepts `POST /api/sync` (payloads written to `generic_vault.jsonl`) and `GET /ws` for Yjs room relay.
- Room-level ACLs are enforced against **permissions in `lifeos.db`**.
- When the permissions table is **empty, the relay allows all** rooms (default-deny only once configured; this is the documented bootstrap behavior).

---

## 9. Telemetry Privacy

- Telemetry is XOR-obfuscated with the fixed key `'lifeos-tel-2026-x'` (`telemetry` domain) — obfuscation, not encryption.
- Server-side rules apply: deduplication, aggregation, and an absolute **cap** on telemetry volume.
- No telemetry leaves the tailnet; the relay/daemon never forwards it to third parties.

---

## 10. Known Limitations & Residual Risks

1. **LWW sync can lose concurrent edits** to the same record across devices (documented in [[04 - LifeOS DevDocs/SYNC_PROTOCOL|Sync Protocol]]).
2. **Telemetry obfuscation is not encryption**; a tailnet attacker with code access can decode payloads.
3. **Relay allow-all when ACL table is empty** — bootstrap convenience; populate permissions before untrusted devices join.
4. **24h JWT lifetime** — a stolen token is valid until expiry; revocation relies on password change + local clear.
5. **No rate limiting** beyond the login brute-force limiter; media and search endpoints may be hammered by authenticated users.

---

## Related Documents

- [[04 - LifeOS DevDocs/WEB_FAILSAFE|Web Failsafe Layer]]
- [[04 - LifeOS DevDocs/EMBEDDED_NETWORK|Embedded Network (tsnet)]]
- [[04 - LifeOS DevDocs/BACKEND_ARCHITECTURE|Backend Architecture]]
- [[04 - LifeOS DevDocs/INFRASTRUCTURE_CONTROL|Infrastructure Control]]