# Web Fail-Safe Architecture

> [!NOTE]
> **Home:** [[04 - LifeOS DevDocs/Home|Home]]


## 1. Zero-Trust Access Gateway
The Fail-Safe layer provides secure, browser-based web access on restricted corporate laptops where embedding `tsnet` or installing the native Flutter app is prohibited.

### Traffic Flow
1.  **Inbound Tunnel:** A Zrok Public Share or Tailscale Funnel exposes the edge router (Caddy) on port `80`/`443`.
2.  **Reverse Proxy Gateway:** Caddy receives the incoming request and delegates the authentication check via `forward_auth` middleware to the local `oauth2-proxy:4180`.
3.  **Authentication & Identity Wall:** The OAuth2-Proxy evaluates the session cookie or redirects the client browser to Google/GitHub SSO. Whitelisted emails listed in `emails.txt` are verified.
4.  **Upstream Settlement:** Authenticated sessions are cleared by Caddy and reverse proxied internally to the `sync-service` container on port `8080`.

## 2. Security Boundaries
*   **No Firewall Ports:** The system does not require opening traditional inbound ports on the local network router.
*   **Brute-Force Immunity:** Authentication offloads entirely to the IdP, benefiting from enterprise-grade rate limiting and 2FA.
*   **Scope Isolation:** The exposed web portal lacks administrative controls over the underlying Hyper-V or Docker Host Daemon infrastructure, preventing total system compromise in case of a session hijack.
