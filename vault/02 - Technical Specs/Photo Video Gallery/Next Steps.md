# Next Steps | Photo Video Gallery

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Photo Video Gallery|Photo Video Gallery]]

## 1. Backend Implementation (Beyond Stubs)
- **Thumbnail Generation:** The Go Daemon must automatically generate compressed `.webp` thumbnails for heavy RAW photos and 4K videos, caching them locally to ensure the Flutter GridView remains at 60FPS.
- **EXIF Parsing:** Extract GPS coordinates and Date Taken from EXIF metadata natively in Go to enable map-based photo searching.

## 2. Data Interconnectivity & Relationships
- **Link to Maps & Live Tracking:** Photos with EXIF GPS data should populate as pins on the offline Map view.
- **Link to Point Star System:** Uploading and organizing 5 media assets awards `+1 Star Point`.

## 3. Open Design Questions
1. Should we implement local machine learning (e.g., running a lightweight YOLO or CLIP model in Go/Python) to automatically tag faces and objects in photos without cloud AI?
2. How should albums/folders be structured? Purely by date, or custom virtual albums in SQLite?
