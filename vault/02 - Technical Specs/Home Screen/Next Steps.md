# Next Steps | Home Screen

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Home Screen|Home Screen]]

## 1. Backend Implementation (Beyond Stubs)
- **Weather / Environment:** Integrate a robust weather parser fetching data via a free API (like Open-Meteo, which requires no API key) and caching it locally in the Go Daemon for fast UI hydration.
- **Telemetry Aggregation:** The Go Daemon needs a specialized `/api/v1/dashboard/summary` endpoint to aggregate data across *all* modules (next task, current points, unread emails) to prevent the Flutter UI from making 15 separate API calls on boot.

## 2. Data Interconnectivity & Relationships
- **Global Hub:** The Home Screen acts as the read-only visual nexus. It must pull `is_dirty` flags from the Drift `SyncQueue` to display network mesh health.
- **Link to Preferences:** The 3x3 widget layout coordinates must remain dynamically linked to the `SystemSettings` table.

## 3. Open Design Questions
1. Do you want to implement Android Native Widgets (AppWidgets) that render this exact data on your phone's actual home screen when the LifeOS app is closed?
2. Should the Home Screen have a "Zen Mode" toggle that visually hides all complex widgets and shows only a clock and the next immediate task?
