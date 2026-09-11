## LifeOS v1.5.33 (Build #71) — Native Startup & URI StateError Hotfix

Welcome to **LifeOS v1.5.33**! This release fixes a critical startup regression introduced in v1.5.32 where native mobile (Android) and desktop (Windows) clients displayed a red error screen upon launching.

---

### Highlights & Bug Fixes

#### 🚀 Native Platform Startup Fix
* **Resolved `Uri.base.origin` `StateError`**: Dart's `Uri.origin` throws a `StateError` on non-HTTP/HTTPS schemes (such as `file:///` on Android and Windows). In v1.5.32, web default URL evaluation was executed before checking platform constraints, causing the initialization bootstrap to fail on startup.
* **Platform-Safe URL Normalization**: All origin and discovery lookups in `AppInitializer`, `ApiClient`, and `PreferencesService` are now strictly guarded by `kIsWeb` and HTTP/HTTPS scheme validation, guaranteeing instant, error-free launches on Android, Windows, and Linux.

#### 📚 Book Library Relative Imports Fix
* Fixed invalid 4-level relative imports in `book_detail_sheet.dart` to adhere to standard module imports, resolving cross-platform compilation errors.
* Added comprehensive startup test suite (`test/startup_initialization_test.dart`) covering native URL discovery and preferences initialization.
