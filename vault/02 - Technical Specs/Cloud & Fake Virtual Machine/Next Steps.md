# Next Steps | Cloud & Fake Virtual Machine

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Cloud & Fake Virtual Machine|Cloud & Fake Virtual Machine]]

## 1. Backend Implementation (Beyond Stubs)
- **Local NAS/SMB Integration:** Map the "Cloud" backup storage directly to a local NAS drive or secure external HDD, executing robust differential backups using `rsync` or Go native file-copy algorithms.
- **Sandbox Execution:** Implement real containerization (via Docker API or Hyper-V) to spin up isolated "Fake VMs" used for testing suspicious files or running isolated quarantine tasks.

## 2. Data Interconnectivity & Relationships
- **Link to Home Management:** Backup logs and NAS storage capacity telemetry should feed directly into the Home Management dashboard.
- **Link to Virtual Machine Management:** The "Fake VM" logic should utilize the same Hyper-V/Docker underlying libraries developed for the VM Management module.

## 3. Open Design Questions
1. Should the cloud backup pipeline support encrypted uploads to an external provider (like AWS S3 or Backblaze B2) via `rclone`, or strictly local NAS?
2. For the "Fake VM", do you prefer Docker containers (faster, lightweight) or full Hyper-V VMs (better isolation)?
