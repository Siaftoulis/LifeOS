# How to Build | Cloud & Fake Virtual Machine

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Cloud & Fake Virtual Machine|Cloud & Fake Virtual Machine]]



This document outlines the step-by-step coding directives and architectural wiring instructions for developer subagents to implement the Cloud & Fake Virtual Machine.

---

## 1. Step-by-Step Implementation Flow

### Step 1: Go Backend Backup Cron & Web OS Portal (Subagent Gamma)
1. **Directory Allocation:** Create the package in `backend/host-daemon/internal/cloud/`.
2. **Cron Scheduler:** Implement background schedule runner (e.g. `github.com/robfig/cron`):
   - Trigger daily checks. Fetch file directories from registered device clients over Tailscale.
3. **Web OS Response Headers:** Enforce cache-wiping response headers inside the static web server file server:
   ```go
   func ServeWebOS(w http.ResponseWriter, r *http.Request) {
       w.Header().Set("Clear-Site-Data", `"cache", "cookies", "storage"`)
       http.ServeFile(w, r, "./web-os/index.html")
   }
   ```

### Step 2: Go Backend Ingestion Quarantine (Subagent Gamma)
1. **Directory Allocation:** Create the pipeline handlers in `backend/host-daemon/internal/sandbox/`.
2. **ClamAV Scanner Integration:** Parse incoming file uploads, save to `/tmp/quarantine/`, and execute a local `clamdscan` shell bridge:
   ```go
   func ScanFile(filePath string) (bool, error) {
       cmd := exec.Command("clamdscan", filePath)
       err := cmd.Run()
       if err != nil {
           // Exit code 1 indicates virus found, exit code 2 indicates scan error
           if exitError, ok := err.(*exec.ExitError); ok && exitError.ExitCode() == 1 {
               return false, nil // Virus found
           }
           return false, err // General execution error
       }
       return true, nil // Clean file
   }
   ```
3. **Inbound Handlers:**
   - If clean: Move file to final `storage_path`, insert metadata into SQLite database.
   - If infected: Securely delete file immediately, log the infection, and execute Point Star deduction hooks.

### Step 3: SQLite Drift Tables & Code Generation (Subagent Beta)
1. **Table Mappings:** Add `DeviceBackupsTable`, `BackupLogsTable`, and `UploadQuarantineTable` class declarations in `client/lib/database/tables.dart`.
2. **SQLite Compilation:** Run build runner:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. **Stream Queries:** Write DAOs inside `client/lib/database/dao.dart` returning streams of active backups and quarantine alerts.

### Step 4: Flutter Presentation & Backup Timeline (Subagent Beta)
1. **Everforest Colors:**
   - Scaffold background: `EverforestColors.bg0`.
   - Device panels: `EverforestColors.bg1` (16px border-radius).
   - Outline borders: 1px thin lines in `EverforestColors.bg2`.
   - Accents: `green` for active/completed states, `red` for failed/infected states, `blue` for data transfers.
2. **Progress & Timeline Grid:**
   - Render horizontal progress bars showing transfer volumes.
   - Implement vertical timelines displaying historical backup logs.

### Step 5: Star Point Integration Hook (Subagent Alpha)
1. **Transaction triggers:** Intercept database mutations for backup logs and upload quarantine:
   - Call `PointStarSystem.addPoints(2)` upon successful device backup completion.
   - Call `PointStarSystem.addPoints(1)` upon verified clean upload via the Web OS portal.
   - Call `PointStarSystem.deductPoints(10)` if ClamAV flags an upload as infected/malicious.
2. **Sync Mark:** Set `is_dirty = 1` to command immediate Tailscale syncing loops.
