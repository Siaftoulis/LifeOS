# Next Steps | Virtual Machine Management

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Virtual Machine Management|Virtual Machine Management]]

## 1. Backend Implementation (Beyond Stubs)
- **Hypervisor Control:** The Go Daemon must execute native PowerShell commands (`Get-VM`, `Start-VM`) for Hyper-V, or API calls to the local Docker daemon, to genuinely start and stop these environments.
- **Remote Execution:** Implement an SSH client within Go or use RustDesk's protocol to allow the Flutter UI to open a remote terminal into the target VM directly from the app.

## 2. Data Interconnectivity & Relationships
- **Link to Cloud & Fake VM:** Shares the same underlying Hyper-V execution infrastructure but for different use cases (general dev vs security sandbox).
- **Link to Dark Web:** VMs might need to be rapidly wiped (snapshot rollback) if they were used for Dark Web downloading.

## 3. Open Design Questions
1. Do you want to build a Flutter-based remote desktop viewer (VNC/RDP) inside LifeOS, or just rely on external apps like RustDesk for the actual screen viewing?
2. Should we support automatic VM snapshots before boot?
