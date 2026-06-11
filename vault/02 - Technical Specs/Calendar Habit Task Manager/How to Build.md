# How to Build | Calendar Habit Task Manager

This document outlines the step-by-step coding directives and architectural wiring instructions for developer subagents to implement the Calendar Habit Task Manager.

---

## 1. Step-by-Step Implementation Flow

### Step 1: Go Backend Voice Transcription Engine (Subagent Gamma)
1. **Directory Allocation:** Create the package in `backend/host-daemon/internal/voice/`.
2. **Audio File Processing:** Parse incoming multipart files inside Go:
   - Accept WAV uploads, write to a temp directory, and verify format.
3. **AI Extraction Handler:** Execute Whisper (or light LLM/API call) to convert audio to text, and extract structural fields using simple regex:
   ```go
   func ParseVoiceIntent(transcription string) (string, int64, int, string) {
       // Search string for keywords: e.g. "tomorrow at 9pm", "high priority", "category work"
       // Parse details and return title, due_date, priority, tag
   }
   ```
4. **Task Inbound Handler:** Automatically write the resulting task parameters directly to `user_tasks` with `synced_at = NULL` and `is_dirty = 1`.

### Step 2: Go Backend Calendar WebSockets Server (Subagent Gamma)
1. **Directory Allocation:** Create the sync hub in `backend/host-daemon/internal/sync/`.
2. **WebSocket Upgrader:** Implement a standard Go WebSocket connection upgrader (e.g. `github.com/gorilla/websocket` or similar):
   - Upgrade HTTP requests to WebSocket connections, storing active clients in a local thread-safe list.
3. **Event Distribution:** Set up a hub loop:
   - When a client issues a POST `/api/v1/calendar/events/create` request, notify all connected peer nodes on the Tailnet immediately.

### Step 3: SQLite Drift Tables & Code Generation (Subagent Beta)
1. **Table Mappings:** Add `CalendarEventsTable`, `UserTasksTable`, `UserHabitsTable`, and `HabitLogsTable` class declarations in `client/lib/database/tables.dart`.
2. **Code Generation:** Run Flutter build triggers:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. **Stream Queries:** Write DAOs in `client/lib/database/dao.dart` returning streams of tasks and habits scheduled for the active day.

### Step 4: Flutter Presentation & Daily Ledger Layout (Subagent Beta)
1. **Everforest Colors:**
   - Scaffold background: `EverforestColors.bg0`.
   - Calendar cells and task lists: `EverforestColors.bg1` (16px border-radius).
   - Card outline borders: 1px thin lines in `EverforestColors.bg2`.
   - Accents: `green` for checked habits, `yellow` for pending tasks, `blue` for primary text.
2. **Micro-Streaks & Gestures:**
   - Implement gesture-driven drag listeners on tasks to trigger slide actions.
   - Scale widget elements: apply dynamic 0.95x scale bounce transitions during list item clicks.
3. **Voice Recording Stream:**
   - Implement audio recording triggers using native Flutter plugin hooks.
   - Stream bytes from the microphone, compress to WAV files, and forward to `/api/v1/voice-parse` REST endpoints.

### Step 5: Star Point Integration Hooks (Subagent Alpha)
1. **Transaction Hooks:** Inject point calculation triggers inside Drift SQLite database mutations:
   - Call `PointStarSystem.addPoints(1)` upon task or habit check-ins.
   - Call `PointStarSystem.addPoints(5)` upon completing high-priority/critical tasks.
   - Call `PointStarSystem.deductPoints(2)` if a daily habit remains unchecked at midnight (determined by cron triggers).
   - Call `PointStarSystem.addPoints(5)` upon completing a 7-day habit streak.
2. **Database Sync Marks:** Set `is_dirty = 1` on target tables to command immediate Tailscale syncing loops.
