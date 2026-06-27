---
title: Aves Local AI Auto-Tagging
status: planned
tags: [gallery, ai, local-first, enhancement]
---

# Local AI Auto-Tagging for Aves Viewer
**Idea:** Implement a completely localized AI service (e.g., using an on-device TF Lite model or a small edge ML model) to automatically scan the local image gallery in the background and generate semantic tags.

## Goals
1. **Offline & Private:** All inference must happen locally without pinging external APIs, ensuring maximum privacy.
2. **Object & Scene Detection:** Recognize generic objects (e.g., cars, animals, trees) and scenes (e.g., beach, night).
3. **Face Recognition:** Ability to detect faces, cluster them locally, and allow the user to assign a name to a clustered face profile.
4. **Integration with Aves Tags:** The output of the AI should map directly to the `tags` list inside `GalleryItem` so it instantly shows up in the Aves Info panel and becomes searchable in the Top App Bar.
5. **Metadata Synergy:** Combine the AI-generated tags with EXIF metadata (time, place, camera model) to create rich, composite queries like "Photos of dogs at the beach last summer."

## Architecture (Draft)
- Run a background isolate/worker that slowly processes untagged photos.
- Use `google_mlkit_image_labeling` or a custom TFLite model running via Flutter.
- Store results in `PreferencesService` or a dedicated SQLite cache.
