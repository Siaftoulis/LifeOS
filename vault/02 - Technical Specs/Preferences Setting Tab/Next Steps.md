# Next Steps | Preferences Setting Tab

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Preferences Setting Tab|Preferences Setting Tab]]

## 1. Backend Implementation (Beyond Stubs)
- **Role-Based Access Control (RBAC):** Implement actual JSON Web Token (JWT) signing in the Go Daemon for the `CHILD` vs `ADMIN` profiles. The Go Daemon must enforce `403 Forbidden` on critical API routes if the token is not an ADMIN token.
- **Node Monitoring:** Replace the Tailscale node stub with real queries to the local `tsnet` status API to show live offline/online statuses of other devices.

## 2. Data Interconnectivity & Relationships
- **Link to Home Screen:** Spatial Grid preferences dynamically rewrite the `main.dart` UI routing matrix.
- **Link to all Gated Modules:** YouTube Client and Virtual Machine Management must query the active `UserProfile` to see if they should engage lockouts.

## 3. Open Design Questions
1. Will there be more than two roles (ADMIN/CHILD), such as a "GUEST" role for temporary device usage?
2. How should we handle PIN recovery if the ADMIN PIN is forgotten?
