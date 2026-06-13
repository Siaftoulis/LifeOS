# Data Binding & Integration Contract

> [!NOTE]
> **Home:** [[04 - LifeOS DevDocs/Home|Home]]


## 1. Network Hardening (HTTP Client)
- **Timeout Protocol**: Enforce strict 2000ms network thresholds on all outbound RPC requests directed to the Go Host Daemon.
- **Resiliency**: Implement an exponential backoff retry loop (e.g., 500ms -> 1000ms -> 2000ms) to gracefully handle ephemeral Tailnet link drops or transient daemon offline states.
- **Identity Context**: Network requests inherently trust the Tailscale `.WhoIs` context verification, deprecating the need for static authentication headers.

## 2. Database Stream Isolation
- **Error Interceptors**: Drift SQLite reactive streams must be fully shielded utilizing a `.handleError` or `.catchError` block.
- **Fallback State**: If the internal SQLite database file throws `SQLITE_BUSY` (read-locked due to a background synchronization commit), the stream must intercept the exception and emit an isolated UI fallback state to prevent layout freezes.
