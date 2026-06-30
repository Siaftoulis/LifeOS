# Proxy Setup & Infrastructure

> [!NOTE]
> **Home:** [[04 - LifeOS DevDocs/Home|Home]] | **Related:** [[04 - LifeOS DevDocs/BACKEND_ARCHITECTURE|Backend Architecture]]

This document outlines the zero-trust identity layer and reverse proxy architecture for the LifeOS host-daemon.

## Components

### 1. OAuth2 Proxy (Identity Wall)
Acts as the gatekeeper for all incoming external traffic.
- **Provider:** Google OAuth2
- **Authorization:** Only emails listed in `backend/proxy/emails.txt` are permitted entry.
- **Port Mapping:** Exposes port `4180` to the host machine.
- **Session:** Uses a secure cookie (`_oauth2_proxy`) with a 168-hour expiration.
- **Upstream:** Passes authenticated traffic to the internal Caddy reverse proxy (`lifeos-proxy:80`).

### 2. Caddy Reverse Proxy
Handles internal routing within the Docker network (`lifeos-net`).
- Directs traffic to the Go daemon (`sync-service`) and acts as a central hub.
- Hardened edge node that serves traffic over `80` and `443`.

### 3. Zrok Tunneling
An open-source alternative to ngrok/Cloudflare Tunnels, providing a public URL for the private service.
- **Target:** Connects directly to `http://proxy:80`.
- **Command:** Uses `zrok share public` in headless mode.
- **Security:** Zrok handles public edge TLS encryption, while OAuth2 Proxy handles authentication.

### 4. RustDesk Server
A self-hosted remote desktop solution deployed on the network.
- **hbbs (ID Server):** Listens on `21115`, `21116`, and `21118`.
- **hbbr (Relay Server):** Listens on `21117` and `21119`.
- **Security:** Uses key-based encryption (`-k _` flag) requiring clients to possess the public key to connect.

## Modifying Access

To grant a new user access:
1. Add their Google email address to `backend/proxy/emails.txt`.
2. Restart the OAuth2 proxy container:
```bash
docker-compose restart oauth2-proxy
```
