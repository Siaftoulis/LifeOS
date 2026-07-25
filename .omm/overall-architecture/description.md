# Overall System Architecture

The LifeOS multi-platform system bridges three core execution tiers:
1. **Flutter Client**: Multi-platform UI (Android, Windows) running local-first Drift SQLite database, Spatial 3x3 Grid UX engine, and client-side delta sync manager.
2. **Trusted Host Daemon**: Go desktop sidecar service communicating via Tailscale `tsnet` WireGuard mesh network, protected by JWT bearer authorization, handling vault file watching and LWW conflict resolution.
3. **Optional Sync Server**: Self-hosted Docker container stack hosting an append-log delta sync hub and PostgreSQL backend.
