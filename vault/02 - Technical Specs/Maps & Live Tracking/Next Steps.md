# Next Steps | Maps & Live Tracking

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Maps & Live Tracking|Maps & Live Tracking]]

## 1. Backend Implementation (Beyond Stubs)
- **Live Location WebSockets:** Replace dummy coordinates with real GPS telemetry pulled from mobile devices running the LifeOS Flutter app. The Go Daemon must broadcast this via the `/api/radar/live` WebSocket endpoint over the Tailscale mesh.
- **Offline Map Tiles:** Implement a local tile server in Go (e.g., serving `.mbtiles` files) so the Map widget can render maps 100% offline without relying on Google Maps or Mapbox APIs.

## 2. Data Interconnectivity & Relationships
- **Link to Home Management:** Proximity triggers (e.g., "User is 1km away from home") should automatically trigger Home Management smart plugs (e.g., turn on AC).
- **Link to Point Star System:** Visiting specific real-world locations (like the gym) can be geo-fenced to automatically award points.

## 3. Open Design Questions
1. Will we use OpenStreetMap data compiled into local vector tiles, or do you prefer raster tiles?
2. Do we need to retain historical location tracking (breadcrumb trails) in the SQLite database, or only the "live" coordinates?
