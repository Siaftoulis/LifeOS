# Web Fail-Safe Architecture

## 1. Zero-Trust Access Gateway
The Fail-Safe layer provides secure, browser-based web access on restricted corporate laptops where embedding `tsnet` or installing the native Flutter app is prohibited.

### Traffic Flow
1.  **Inbound Tunnel:** A Zrok Public Share or Tailscale Funnel exposes port `4180` to the internet.
2.  **Identity Proxy:** The OAuth2-Proxy container intercepts all incoming requests.
3.  **Authentication:** The proxy delegates authentication to a Google/GitHub Identity Provider. Only identities whitelisted in `emails.txt` are authorized.
4.  **Reverse Proxy:** Authenticated sessions are passed upstream to the Caddy reverse proxy on port `80`.

## 2. Security Boundaries
*   **No Firewall Ports:** The system does not require opening traditional inbound ports on the local network router.
*   **Brute-Force Immunity:** Authentication offloads entirely to the IdP, benefiting from enterprise-grade rate limiting and 2FA.
*   **Scope Isolation:** The exposed web portal lacks administrative controls over the underlying Hyper-V or Docker Host Daemon infrastructure, preventing total system compromise in case of a session hijack.
