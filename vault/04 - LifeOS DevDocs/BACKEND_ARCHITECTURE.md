# Backend Architecture

> [!NOTE]
> **Home:** [[04 - LifeOS DevDocs/Home|Home]] | **Related:** [[04 - LifeOS DevDocs/PROXY_SETUP|Proxy Setup]]

The LifeOS host-daemon backend is written in Go and operates under strict constraints regarding cyclomatic complexity and file size (max 50-100 lines per file).

## Core Philosophy

1. **Stateless Handlers**: All API handlers receive requests and map directly to store operations.
2. **Domain-Driven Directory Structure**: Functionality is modularized into distinct directories inside `internal/`.
3. **Atomic File Separation**: Each domain splits its models, data access (store), and HTTP routing into different files.

## Modules

### Authentication (`internal/auth`)
- **`users_model.go`**: Defines the central `User` struct and its JSON mapping.
- **`users_store.go`**: Handles `sync.RWMutex` maps, reading/writing `users.json`, and seeding the default admin user.
- **`users_ops.go`**: Exposes operations like `AuthenticateUser` with bcrypt verification and profile updates.
- **`router.go`**: Maps endpoints (`/api/v1/users/login`, `/api/v1/users/create`) to operational methods.

### Books (`internal/books`)
- **`store.go`**: Manages the local JSON database (`data/books.json`) mapping reading progress and highlights.
- **`handlers.go`**: Exposes REST endpoints to list books, sync page progress, and save highlights.

### System (`internal/system`)
- **`router.go`**: Base HTTP router mapping settings, tailscale node status, and app categorization.
- **`settings.go`**: Loads and saves system settings from `data/system_settings.json`.
- **`tailscale.go`**: Calls out to the local Tailscale CLI (`tailscale status --json`) to fetch mesh node statuses.
- **`apps_classifier.go`**: Dual-method categorizer. First attempts Gemini AI REST inference for app categorizing, falling back to a hardcoded string-matching heuristic.
