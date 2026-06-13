# What to Do | Cloud & Fake Virtual Machine

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Cloud & Fake Virtual Machine|Cloud & Fake Virtual Machine]]



This document outlines the development tasks and subagent assignments for implementing the Cloud & Fake Virtual Machine, combining automated cloud backups, Web OS anonymous interfaces, and incoming file sanitization.

---

## 1. Subagent Alpha (Lead Architect) Commands
- [ ] **DATA_SCHEMAS.md Integration:** Update the system database layout in `vault/04 - LifeOS DevDocs/DATA_SCHEMAS.md` to define relational schemas for the `device_backups`, `backup_logs`, `web_sessions`, and `upload_quarantine` tables.
- [ ] **Point Star Reward Logic:** Define tracking rules for the Point Star System:
  - Add **+2 Star Points** to the user's ledger for completing a successful daily device backup.
  - Add **+1 Star Point** to the user's ledger for uploading and verifying a clean file through the Web OS portal.
  - Deduct **-10 Star Points** as a severe security penalty if an uploaded file contains malware or runs prohibited executable hooks.
- [ ] **Conflict Resolution Specifications:** Define sync conflict schemas for backup timestamps, ensuring client-driven Last-Write-Wins (LWW) resolution.
- [ ] **Milestone Logging:** Document all database schema updates, sync rules, and reward calculations in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) upon completion.

---

## 2. Subagent Beta (Frontend & Local Storage) Commands
- [ ] **Drift Table Generation:** Create Drift models inside `client/lib/database/` for:
  - `DeviceBackups`: Fields for id, name, last_backup, storage_path, backup_status.
  - `BackupLogs`: Fields for log_id, device_id, timestamp, files_count, bytes_transferred.
  - `UploadQuarantine`: Fields for file_id, file_name, file_size, scan_status (PENDING, CLEAN, INFECTED).
  - Run database code generators to create matching DAOs and stream builders.
- [ ] **Cloud Dashboard UI:** Build the main Cloud & Backup view in `client/lib/presentation/widgets/` following the Everforest color scheme:
  - Scaffold wrapper container background set to `EverforestColors.bg0`.
  - Registered device cards and log lists set to `EverforestColors.bg1`.
  - 1px thin outlines set to `EverforestColors.bg2` around each component card.
  - Custom typography using `EverforestColors.fg` for headers and `grey` for status labels.
- [ ] **Backup Status Panel:** Renders active device connection indicators, scheduled daily backup loops, and file transfer progress bars.
- [ ] **Change Documentation:** Update the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) with details of all new Drift tables, device backup trackers, and upload quarantine UIs created for the Cloud & Fake VM module.

---

## 3. Subagent Gamma (Systems, Security & Network) Commands
- [ ] **Automated Backup Cron Service:** Write a background Cron service in Go (`backend/host-daemon/internal/cloud/`) that executes daily scheduling:
  - Pull target file archives (configurations, images) from registered family clients over Tailscale.
- [ ] **Web OS HTTP Router:** Serve a stateless HTML5/React/Flutter Web client interface and file upload handler on port 8081.
- [ ] **Stateless Session Cleaner Headers:** Configure HTTP response headers for the Web OS portal to enforce instant browser cache wipes on unload:
  - Inject headers: `Clear-Site-Data: "cache", "cookies", "storage"`.
- [ ] **Security Inspection Pipeline:** Write a Go wrapper executing ClamAV daemon commands (`clamdscan`) on uploaded files inside a temporary directory:
  - If malware is found, immediately delete the binary, notify the database, and write 'infected' status to the `upload_quarantine` table.
- [ ] **REST API Sync Endpoints:** Register server handlers in the daemon configuration:
  - `GET /api/v1/cloud/backups`: Retrieve active backup statistics and list of devices.
  - `POST /api/v1/cloud/upload`: Endpoint for incoming files passing directly through the ClamAV scanner sandbox.
- [ ] **Execution Log Update:** Record details of the backup Cron runner, Web OS server, ClamAV scanner, and HTTP endpoints in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) before final delivery.
