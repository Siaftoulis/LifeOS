---
id: "a1b2c3d4-0005-4a5b-9c0d-lifeosinfracontrol"
type: "lifeos_infrastructure_control"
last_modified: 1784500000000
sync_status: "clean"
---

# Technical Specification: Infrastructure Control & Virtualization

> [!NOTE]
> **Home:** [[04 - LifeOS DevDocs/Home|Home]] | **Related:** [[04 - LifeOS DevDocs/EMBEDDED_NETWORK|Embedded Network]] · [[04 - LifeOS DevDocs/WEB_FAILSAFE|Web Failsafe]] · [[04 - LifeOS DevDocs/BACKEND_ARCHITECTURE|Backend Architecture]]

This specification details the infrastructure-control capabilities of the LifeOS Host Daemon, a secure background service running on the target Windows 11 Pro machine: remote execution of Hyper-V and Docker APIs, power management, remote directory streaming, and remote desktop visualization integration.

---

## Current Status (August 2026)

> [!NOTE]
> The earlier "Codebase Routing Discrepancy" note claimed the daemon only listened on the generic `/api/v1/action` endpoint and ignored the client's `/api/vm/toggle` calls. That is no longer true: `internal/vm/router.go` now serves the dedicated VM domain — `/api/v1/vm`, `/api/v1/vm/toggle`, `/api/v1/vm/discovery`, `/api/v1/vm/explore`.

*   The HMAC-signed action schema has been **superseded by the global JWT auth gate** for general API access. HMAC signing still exists in `crypto/hmac.go` (`HMAC_SECRET`, `VerifyHMAC`) for infrastructure actions.
*   **Web portal / remote access:** the Funnel portal can trigger these admin actions from a browser behind the JWT gate (see [[04 - LifeOS DevDocs/WEB_FAILSAFE|Web Failsafe]]).

---

## 1. LifeOS Host Daemon Architecture

The Host Daemon runs natively as a Windows service, listening on the internal `tsnet` mesh (`:50051`). It has elevated permissions to execute native PowerShell cmdlets and Docker CLI arguments.

### Core Responsibilities
*   **Hyper-V / VM Orchestration:** start, stop, and query local virtual machines (`hyperv.go` — `Start-VM`, `Stop-VM`, `Get-VM` PowerShell cmdlets; plus the `internal/vm` domain backed by its own SQLite DB in `data/`).
*   **Docker Container Orchestration:** reboot sync relays or restart isolated proxy containers (`backend/docker-compose.yml`).
*   **Remote File System Explorer:** stream local Windows directory trees over the secure tailnet to the Flutter client (`GET /api/v1/vm/explore?path=...`).
*   **Power Management:** trigger Wake-on-LAN (WOL) magic packets (`wol.go` — `BroadcastMagicPacket` broadcasts on UDP port 9 with a `255.255.255.255` fallback).

---

## 2. Remote Action API

### Legacy Generic Action Endpoint (`POST /api/v1/action`)
The daemon historically exposed a single typed JSON action endpoint (`handler.go`):

```json
{
  "action_type": "START_VM | STOP_VM | GET_VMS | TRIGGER_WOL",
  "target_id": "VM name or MAC address",
  "timestamp": 1784500000000,
  "signature": "HMAC-SHA256 signature"
}
```

*   **`START_VM` / `STOP_VM`:** maps to PowerShell `Start-VM -Name <target_id>` and `Stop-VM -Name <target_id>` (`hyperv.go`).
*   **`GET_VMS`:** runs PowerShell list cmdlets returning names and running states of configured VMs.
*   **`TRIGGER_WOL`:** sends a UDP magic packet to the MAC address in `target_id` (`wol.go`).

This endpoint is still registered for compatibility, but it now sits behind the global JWT gate like every other route; the HMAC `signature` field is verified via `crypto/hmac.go`.

### Current VM Domain (`internal/vm/router.go`)
| Route | Method | Behavior |
|---|---|---|
| `/api/v1/vm` | GET | List VMs from the `virtual_machines` SQLite table (id, name, type, state, ram) |
| `/api/v1/vm/toggle` | POST | Set VM state (`RUNNING` / `STOPPED`) by `vm_id` + `action` |
| `/api/v1/vm/discovery` | GET | Tailnet peer discovery via `tailscale status --json` (stub IP fallback) |
| `/api/v1/vm/explore` | GET | List directory entries at `?path=` |

---

## 3. Remote Desktop Protocol Integration

To provide full visual control of the host machine, the LifeOS architecture integrates open-source low-latency streaming protocols.

### RustDesk Integration (Standard Desktop Access)
*   **Topology:** a self-hosted RustDesk Server (hbbs/hbbr) runs inside the `backend/docker-compose.yml` stack (ports `21115`–`21119`).
*   **Access:** the Flutter client launches the native RustDesk viewer library, dialing through the tailnet.

### Sunshine / Moonlight (High-Performance GPU Streaming)
*   **Topology:** for visually intensive tasks (game streaming, 3D rendering), Sunshine is installed on the Windows 11 host natively.
*   **Access:** the Flutter client integrates the Moonlight protocol viewer, negotiating streams over the secure mesh network on port `47989`.

---

## Related Specifications
*   [[04 - LifeOS DevDocs/EMBEDDED_NETWORK|Embedded Network Protocol (tsnet)]]
*   [[04 - LifeOS DevDocs/DATA_SCHEMAS|Split-Storage & Frontmatter Architecture]]
*   [[04 - LifeOS DevDocs/WEB_FAILSAFE|Web Fail-Safe Layer]]