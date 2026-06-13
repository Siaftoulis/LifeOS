# Core UI Dashboard Architecture

> [!NOTE]
> **Home:** [[04 - LifeOS DevDocs/Home|Home]]


## 1. Adaptive Breakpoint System
The unified client employs Flutter's `LayoutBuilder` to construct fluid, cross-platform layouts based on real-time screen constraints:
*   **Desktop Viewport (Windows):** Renders a spacious 3-column data-dense grid structure. Inherits navigation via a permanent leading `NavigationRail`.
*   **Mobile Viewport (Android):** Collapses dynamically into a stacked vertical matrix driven by an intuitive `BottomNavigationBar`.

## 2. Neo-Minimalist Dark Theme
*   **Aesthetic Profile:** Dark Neo-Minimalism optimized for modern sRGB and OLED panels.
*   **Primary Palette:** Deep Charcoal backgrounds (`#0F1115`) layered under elevated glassmorphic surface overlays (`#1A1D24` with `ImageFilter.blur`).

## 3. Optimistic UI State Engine
To guarantee zero-latency perception on high-frequency interactions:
*   **Immediate Feedback:** Toggles (e.g., Habit completion, VM switches) update the localized in-memory `StateNotifier` instantaneously.
*   **Background Settlement:** Drift SQLite commits and Host Daemon RPC transmissions execute silently behind the scenes.

## 4. Unified Route Handler Strategy
*   Utilizes a central declarative router mapped to application sub-states.
*   Deep linking ensures seamless state hydration regardless of the invocation pathway.
