# What to Do | Accounting

This document establishes the exact development task checklists and integration requirements for the Accounting module, delegated as commands to the autonomous subagents.

---

## 1. Subagent Alpha (Lead Architect) Commands
- [ ] **DATA_SCHEMAS.md Update:** Verify that the relational schema, column definitions, and encryption flags for the `accounting_credentials` and `accounting_documents` tables are updated in `vault/04 - LifeOS DevDocs/DATA_SCHEMAS.md`.
- [ ] **Validation Verification:** Define LWW (Last-Write-Wins) sync conflict-resolution vectors for encrypted document binary blobs in the sync protocol specification.
- [ ] **Milestone Logging:** Document all system architecture revisions, database schema alterations, and sync rules in [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) upon completing this task block.

---

## 2. Subagent Beta (Frontend & Local Storage) Commands
- [ ] **Drift Table Definitions:** Generate the Dart models for `AccountingCredentials` and `AccountingDocuments` inside `client/lib/database/` and run the build generator to create the SQLite DAO mappings.
- [ ] **UI Presentation Layer:** Build the `AccountingView` widget inside `client/lib/presentation/widgets/` using the Everforest Minimalist Flat-Line UI properties:
  - Scaffolding container set to `EverforestColors.bg0`.
  - Category grids and detail cards set to `EverforestColors.bg1`.
  - Clean 1px outlines in `EverforestColors.bg2` around each card container.
  - Sans-serif typography using `EverforestColors.fg` for headers and `grey` for card labels.
- [ ] **Decryption Passcode Curtain:** Implement the `SecurityCurtain` overlay widget. Before displaying sensitive credentials (AFM, AMKA) or rendering scanned document thumbnails, display a numeric PIN dial overlay.
- [ ] **Local Path Links:** Bind the Document View cards to local file references mapped by the database, triggering the native PDF reader or image viewer inside Flutter.
- [ ] **Change Documentation:** Update the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) recording any newly generated SQLite Drift tables, Flutter UI files, and state notifier bindings implemented for the Accounting module.

---

## 3. Subagent Gamma (Systems, Security & Network) Commands
- [ ] **AES-256 Encryption Engine:** Write the local file-encryption and decryption module in Go (`backend/host-daemon/crypto/`) using AES-256-GCM. Derivate the secret key from the user's PIN using PBKDF2 with SHA-256 hashing.
- [ ] **JSON-RPC Schema Handlers:** Expose JSON-RPC API methods in the local Go daemon (`backend/host-daemon/schema.json`):
  - `QueryAccountingCredentials(pin_hash)`: Returns decrypted string metadata (AFM, AMKA values).
  - `DecryptAccountingDocument(document_id, pin_hash)`: Decrypts the binary scan payload on-the-fly and returns temporary raw bytes to the client shell over the secure Tailscale loop.
- [ ] **Greek Portal WebViews:** Embed sandboxed native system WebView adapters for Android (Kotlin) and Windows (C++/WebView2) to load government portal links (GOV.gr, EFKA, Taxisnet) securely.
- [ ] **Execution Log Update:** Document the cryptographic handlers, REST endpoints, and system WebView hooks created for Accounting in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) before handing off execution.
