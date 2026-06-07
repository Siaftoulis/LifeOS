# Dynamic Subagent Delegation Boundaries

This document establishes the execution scopes, read/write permissions, and mandates for the multi-agent assembly line working on the LifeOS workspace. The Main Orchestrator Agent enforces these boundaries to prevent context pollution.

---

## 1. Subagent Alpha (Lead Architect)
*   **Scope Restriction:** 
    *   **Read:** Global Read access across the workspace (specifically including `vault/00 - LifeOS DevDocs/` and `.agent/`).
    *   **Write:** Restrained exclusively to `vault/00 - LifeOS DevDocs/` and `.agent/`.
*   **Mandate:** Authoritarian owner of system specifications, database schemas, sync protocols, and architectural tracking. Acts as the final reviewer for all other subagents' proposals.

## 2. Subagent Beta (Frontend & Local Storage Specialist)
*   **Scope Restriction:** 
    *   **Read:** Global Read access across the workspace (including `vault/00 - LifeOS DevDocs/` and `.agent/`).
    *   **Write:** Restrained exclusively to `/client/` and `vault/10 - Journal & Tracking/`.
*   **Mandate:** Controls the 3x3 Spatial UI Grid, Feature Registry plugins, local SQLite structures, and the Obsidian file-system watcher.

## 3. Subagent Gamma (Systems, Security & Network Engineer)
*   **Scope Restriction:** 
    *   **Read:** Global Read access across the workspace (including `vault/00 - LifeOS DevDocs/` and `.agent/`).
    *   **Write:** Restrained exclusively to `/backend` and platform-native directories (`/client/windows`, `/client/android`).
*   **Mandate:** Prepares the secure Docker configurations, the OAuth2 identity wall parameters, and maps out the embedded `tsnet` background runtime loop.

---

## 4. Cross-Agent Handoff Protocol

To safely bridge implementation scopes without violating the strict Write isolation boundaries, subagents must exchange parameters and configurations through designated files:

### Protocol Specifications
1. **Network Configuration & Ports:**
   - **Gamma** defines network ports, proxy mappings, and tunnel parameters. Gamma writes these configurations to `backend/.env` or `client/assets/config/network.json`.
   - **Beta** parses `client/assets/config/network.json` at client compile-time or reads values dynamically to configure target hosts.
2. **Schema & Models Generation:**
   - **Alpha** designs schema specs and updates `DATA_SCHEMAS.md`.
   - **Beta** translates structural updates to Dart/Drift models (`client/lib/`) and triggers code generation.
3. **Daemon JSON-RPC Schema Contract:**
   - **Gamma** implements and publishes the Go Daemon's JSON-RPC structures in `backend/host-daemon/schema.json`.
   - **Beta** consumes the JSON-RPC models to align Flutter UI commands with the backend daemon listeners.
