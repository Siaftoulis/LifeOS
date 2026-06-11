# What to Do | Calendar Habit Task Manager

This document outlines the development tasks and subagent assignments for implementing the Calendar Habit Task Manager, combining events, tasks, habits, voice input, and real-time syncing.

---

## 1. Subagent Alpha (Lead Architect) Commands
- [ ] **DATA_SCHEMAS.md Integration:** Update the system database layout in `vault/04 - LifeOS DevDocs/DATA_SCHEMAS.md` to define relational schemas for the `calendar_events`, `user_tasks`, `user_habits`, and `habit_logs` tables.
- [ ] **Point Star Reward Logic:** Define tracking rules for the Point Star System:
  - Add **+1 Star Point** to the user's ledger for completing a standard checklist task or daily habit.
  - Add **+5 Star Points** for completing a high-priority or critical task.
  - Deduct **-2 Star Points** from the active balance if a scheduled daily habit is neglected or skipped.
  - Apply streak multipliers: **+5 Star Points** bonus for maintaining a 7-day consecutive habit check-in streak.
- [ ] **Conflict Resolution Specifications:** Define sync validation schemas for group calendar entries, utilizing timestamp vector comparison to prevent data truncation.
- [ ] **Milestone Logging:** Document all database schema updates, sync rules, and reward calculations in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) upon completion.

---

## 2. Subagent Beta (Frontend & Local Storage) Commands
- [ ] **Drift Table Generation:** Create Drift models inside `client/lib/database/` for:
  - `CalendarEvents`: Fields for id, title, start_time, end_time, color_code, is_shared, updated_at, is_dirty.
  - `UserTasks`: Fields for id, title, notes, priority (1-4), status (TODO, IN_PROGRESS, DONE), due_date, completed_at, updated_at, is_dirty.
  - `UserHabits`: Fields for id, name, frequency_cron, target_streak, updated_at, is_dirty.
  - `HabitLogs`: Fields for id, habit_id, checkin_date, points_awarded, is_dirty.
  - Run database code generators to create matching DAOs and stream builders.
- [ ] **Calendar Habit Dashboard UI:** Build the main CHTM view in `client/lib/presentation/widgets/` following the Everforest color scheme:
  - Scaffold wrapper container background set to `EverforestColors.bg0`.
  - Ledger calendar month-view and card lists set to `EverforestColors.bg1`.
  - 1px thin outlines set to `EverforestColors.bg2` around each component card.
  - Custom typography using `EverforestColors.fg` for headers and `grey` for status labels.
  - Categorized highlighting: `green` for completed habits, `yellow` for pending tasks, and `blue` for primary text.
- [ ] **Slide-to-Complete Gestures:** Implement interactive gesture detectors allowing users to slide list tasks left to complete, or right to delete/reschedule, triggering instant optimistic UI state changes.
- [ ] **Voice Capture Microphone Widget:** Add a microphone quick-action button on the interface. Recording must write raw audio bytes to a local `.wav` file, encode it to a Base64 stream, and POST it to the Go backend `/api/v1/voice-parse` endpoint.
- [ ] **Change Documentation:** Update the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) with details of all new Drift tables, dynamic list UI gestures, and voice recording buttons created for the Calendar Habit Task Manager.

---

## 3. Subagent Gamma (Systems, Security & Network) Commands
- [ ] **AI voice-parse Handler:** Write the Go backend voice-processing router (`backend/host-daemon/internal/voice/`) that receives `.wav` files:
  - Process voice input through a local LLM handler or Whisper API wrapper to transcribe task titles, extract due dates, parse priorities, and identify tags.
  - Insert the parsed results directly into the database `user_tasks` table.
- [ ] **WebSocket Real-time Sync Router:** Implement real-time WebSocket communication in Go (`backend/host-daemon/internal/sync/`) to broadcast group calendar modifications instantly to Tailnet clients.
- [ ] **REST API Sync Endpoints:** Register server handlers in the daemon configuration:
  - `GET /api/v1/calendar/events`: Retrieve personal and shared appointments.
  - `POST /api/v1/calendar/events/create`: Add new calendar entries and notify peer clients.
  - `POST /api/v1/voice-parse`: Accept voice streams and return structured task JSON objects.
- [ ] **Execution Log Update:** Record details of the Go audio parser, WebSocket router, and REST endpoints in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) before final delivery.
