# LifeOS Monorepo

Welcome to the **LifeOS** codebase. This is a local-first, offline-first personal workspace platform built using **Flutter** for the frontend, **Go** for the backend host daemon, and a lightweight Go synchronization service.

---

## Monorepo Structure

- `client/`: The Flutter desktop and mobile application workspace.
- `backend/host-daemon/`: Background service managing infrastructure, Hyper-V/Docker execution, and remote desktop pipelines.
- `server/`: Lightweight synchronization server implementing delta-based transactional syncing.
- `vault/`: Obsidian technical specifications, project logs, and sprint tasks.

---

## Easy New PC Setup

To prepare a new PC for development automatically, run the setup bootstrapper script. This script checks for required tools (**Git**, **Go**, **Flutter**) and automatically installs them via `winget` (Windows Package Manager) if missing, then fetches all package dependencies.

### Installation Instructions

1. Open **PowerShell** as Administrator.
2. Enable script execution if not already enabled:
   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
3. Run the setup script:
   ```powershell
   .\setup.ps1
   ```
4. Restart your terminal or IDE (VS Code / Android Studio) once completed to apply the new system paths.

---

## Running the Application

### 1. Flutter Client
Navigate to the client directory and run the Flutter application:
```bash
cd client
flutter run
```

### 2. Go Backend Host-Daemon
Navigate to the host-daemon directory and execute:
```bash
cd backend/host-daemon
go run main.go
```

### 3. Sync Server
Navigate to the server directory and run:
```bash
cd server
go run main.go
```