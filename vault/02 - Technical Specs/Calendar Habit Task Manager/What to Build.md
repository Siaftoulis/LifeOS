# What to Build | Calendar Habit Task Manager

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Calendar Habit Task Manager|Calendar Habit Task Manager]]



This document specifies the exact SQLite schemas, JSON-RPC/WebSocket API paths, and Flutter widget components to build for the Calendar Habit Task Manager.

---

## 1. Database Architecture (SQLite / Drift)

Four tables must be defined in the SQLite cache layer to support events, checklist items, habits, and progress counters:

```sql
-- Schema for Calendar Events
CREATE TABLE IF NOT EXISTS calendar_events (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    start_time INTEGER NOT NULL,       -- Unix millisecond timestamp
    end_time INTEGER NOT NULL,         -- Unix millisecond timestamp
    color_code TEXT DEFAULT '#89B4FA', -- Hex color string
    is_shared INTEGER DEFAULT 0,       -- 0: Private, 1: Group Shared
    updated_at INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0
);

-- Schema for Checklist Tasks
CREATE TABLE IF NOT EXISTS user_tasks (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    notes TEXT,
    priority INTEGER DEFAULT 1,        -- 1: Low, 2: Medium, 3: High, 4: Critical
    status TEXT DEFAULT 'TODO',        -- 'TODO', 'IN_PROGRESS', 'DONE'
    due_date INTEGER,                  -- Optional Unix millisecond timestamp
    completed_at INTEGER,              -- Optional Unix millisecond timestamp
    updated_at INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0
);

-- Schema for Habits
CREATE TABLE IF NOT EXISTS user_habits (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    frequency_cron TEXT NOT NULL,      -- Cron format representation
    target_streak INTEGER DEFAULT 0,
    updated_at INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0
);

-- Schema for Habit Completion Logs
CREATE TABLE IF NOT EXISTS habit_logs (
    id TEXT PRIMARY KEY,
    habit_id TEXT NOT NULL,
    checkin_date INTEGER NOT NULL,     -- Date timestamp (at midnight)
    points_awarded INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0,
    FOREIGN KEY(habit_id) REFERENCES user_habits(id) ON DELETE CASCADE
);
```

---

## 2. API Specifications (Go Backend Daemon)

The host daemon manages voice file transcription parsing and WebSockets group synchronization loops over the Tailscale network.

### REST Endpoints
- **Voice Inbound Parser:**
  - `POST /api/v1/voice-parse`
  - Content-Type: `multipart/form-data` containing the `.wav` file bytes.
  - Response: `JSON` containing the parsed task parameters:
    ```json
    {
      "title": "Clean room",
      "due_date": 1780000000000,
      "priority": 2,
      "category": "Home"
    }
    ```
- **Shared Calendar CRUD Actions:**
  - `GET /api/v1/calendar/events`
  - `POST /api/v1/calendar/events/create`

### WebSockets Endpoint
- **Shared Live Synchronization:**
  - `ws://localhost:8080/api/v1/calendar/live`
  - Response: Real-time broadcast payloads when other group/family users modify the shared calendar.

---

## 3. UI Component Registry (Flutter Client)

All widgets are declared inside `client/lib/presentation/widgets/` or plugins:

- **`CHTMView`:** Main module screen. Renders a monthly/weekly calendar grid header coupled with the Daily Ledger detail card underneath.
- **`DailyLedgerCard`:** Combined ledger block displaying events, habits, and tasks scheduled for the active date.
- **`SlideableTaskCard`:** Swipe gesture container. Dragging left completes the task, dragging right opens a reschedule sheet.
- **`HabitProgressGrid`:** Loop-style layout presenting habit streaks, check-in history dots, and target counts.
- **`VoiceRecorderDialog`:** Compact microphone panel displaying audio recording overlays and transcription progress buffers.
