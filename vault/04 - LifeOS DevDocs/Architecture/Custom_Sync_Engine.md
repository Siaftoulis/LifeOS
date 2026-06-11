# Proprietary Custom Sync Engine Architecture

## 1. Network Replication Protocol
The custom sync engine completely replaces third-party dependencies (like CouchDB) by enforcing a strictly controlled point-to-point data transmission loop:
`Drift SQLite Client -> JSON Payload Engine -> Tailnet -> Go Sync Service Backend`

## 2. Synchronization Mechanisms
*   **State Vector Clocking:** Utilizes a custom Timestamp/Version-Vector token on each database payload entity. The Go backend enforces deterministic Last-Write-Wins (LWW) resolution mapping based on execution timestamps, eliminating write-conflict race conditions.
*   **Binary Delta Chunking:** Extracts and isolates only recently modified Drift SQLite table rows (deltas), packaging them into dense JSON sync-packets. This bypasses complete database replication dumps, drastically reducing network transmission bandwidth across mobile mesh links.
