# Native Widget System Architecture

> [!NOTE]
> **Home:** [[04 - LifeOS DevDocs/Home|Home]] | **Related:** [[04 - LifeOS DevDocs/Architecture/Core_UI_Dashboard|Core UI Dashboard]] · [[04 - LifeOS DevDocs/UI_UX_GUIDELINES|UI/UX Guidelines]] · [[04 - LifeOS DevDocs/Architecture/Data_Binding|Data Binding]] · [[Home Screen]] · [[Obsidian Zen Editor]]


## 1. Concurrent Database Configuration
To ensure safe concurrent access between the active application and the background widgets:
*   **Write-Ahead Logging (WAL):** SQLite PRAGMA `journal_mode=WAL` is enforced at the Drift engine level. This prevents read/write locks from colliding when the native widget attempts to fetch data while the main app is syncing.
*   **Event Debouncing:** All reactive data streams targeting the Widget bridge implement a strict `300ms` debounce threshold to mitigate CPU spiking during rapid batch operations.

## 2. Android Home Screen Widgets
*   **Data Pipeline:** `Drift SQLite Engine -> MethodChannel (Data Payload Bridge) -> Kotlin AppWidgetProvider -> RemoteViews`
*   **Mechanics:** The Flutter client computes metrics and pushes structured JSON to the MethodChannel. The native Kotlin layer consumes this to construct high-performance `RemoteViews`.

## 3. Windows 11 Desktop Widgets
*   **Architecture:** The desktop layout utilizes the `desktop_multi_window` plugin.
*   **Viewport:** The secondary window compiles as a frameless, transparent overlay profile anchored to the Windows Desktop layer.
*   **Data Access:** The secondary overlay links directly to the shared `LifeOS.sqlite` local database path. To avoid conflicts, this sub-window initiates the connection explicitly in Read-Only mode.
