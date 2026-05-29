# Synchronization Protocols

## 1. Field-Level Delta Logging (The `sync_queue`)
To avoid entire document overwrites (which cause conflicts in rapidly modified markdown notes), the client implements a strict property-level mutation logger.

When an entity is modified, an interceptor records the exact property change:
```sql
CREATE TABLE sync_queue (
  id TEXT PRIMARY KEY,
  target_table TEXT NOT NULL,
  record_id TEXT NOT NULL,
  field_name TEXT NOT NULL,
  old_value TEXT,
  new_value TEXT,
  client_updated_at INTEGER NOT NULL,
  synced_state INTEGER DEFAULT 0
);
```

## 2. Last-Write-Wins (LWW) Resolution
When the client establishes a `tsnet` connection to the host, it flushes the `sync_queue`.
*   The Host evaluates the `client_updated_at` timestamp.
*   If the client's timestamp is newer than the host's current `updated_at` for that specific field, the mutation is applied to the markdown file.
*   Otherwise, the mutation is discarded as stale.

## 3. Clock Skew Mitigation
Clients sync their local drift clocks via an NTP check during the initial Tailscale handshake to ensure that millisecond-level LWW comparisons remain accurate across mobile networks.
