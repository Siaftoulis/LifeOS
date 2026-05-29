# Dynamic Subagent Delegation Boundaries

This document establishes the execution scopes, read/write permissions, and mandates for the multi-agent assembly line working on the LifeOS workspace. The Main Orchestrator Agent enforces these boundaries to prevent context pollution.

---

## 1. Subagent Alpha (Lead Architect)
*   **Scope Restriction:** Read/Write restricted to `vault/00 - LifeOS DevDocs/` and `.agent/`.
*   **Mandate:** Authoritarian owner of system specifications, database schemas, sync protocols, and architectural tracking. Acts as the final reviewer for all other subagents' proposals.

## 2. Subagent Beta (Frontend & Local Storage Specialist)
*   **Scope Restriction:** Read/Write restricted to `/client/` and `vault/10 - Journal & Tracking/`.
*   **Mandate:** Controls the UI, local SQLite structures, and the Obsidian file-system watcher.

## 3. Subagent Gamma (Systems, Security & Network Engineer)
*   **Scope Restriction:** Read/Write permission locked to `/backend` and platform-native directories (`/client/windows`, `/client/android`).
*   **Mandate:** Prepares the secure Docker configurations, the OAuth2 identity wall parameters, and maps out the embedded `tsnet` background runtime loop.
