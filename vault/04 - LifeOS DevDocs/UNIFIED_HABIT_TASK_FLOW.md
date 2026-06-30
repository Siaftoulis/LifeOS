# Unified Habit & Task Flow

> [!NOTE]
> **Home:** [[04 - LifeOS DevDocs/Home|Home]] | **Related:** [[04 - LifeOS DevDocs/DATA_SCHEMAS|Data Schemas]]

This document outlines the unified data flow that connects frontend SQLite completion actions (Habits, Tasks, Quests) to the backend Go daemon for RPG stat processing.

## 1. Flow Trigger
The flow begins when a user clicks "Complete" on a task, habit, or quest in the `CHTMView` or `QuestBoard`.

## 2. Local State Mutation (Flutter)
- The local SQLite store (`user_habits`, `user_tasks`, or `calendar_events`) is updated immediately via `ChtmDao` for instant UI feedback (optimistic update).
- An entry is optionally created in `habit_logs`.

## 3. The Backend Call
- `ChtmDao` triggers a fire-and-forget POST request to `/api/v1/player/task/complete`.
- **Payload**: `{ "task_id": "...", "attribute": "intelligence", "base_xp": 15, "base_points": 10, "is_sick": false }`
- **Offline Logic**: If the backend is unreachable, the request is queued locally in the `pending_rewards` table and processed later.

## 4. Backend Processing (Go)
1. **Decode Payload**: The request is intercepted by `internal/player/router.go`.
2. **Illness Check**: Evaluates if the user has active debuffs (Stasis, Illness) which modify XP modifiers.
3. **Atrophy & Decay**: Calculates XP decay since the last activity, reducing points/attributes if applicable.
4. **Persist State**: The newly calculated `PlayerStats` (XP, level, attributes) are saved securely to `./data/player.json`.
5. **Return**: The backend returns the calculated exact point delta and the new XP totals.

## 5. UI Reward Delivery
- **Points Update**: The Flutter client parses the response and calls `PointsDao.awardPoints()`, incrementing `system_users.current_points` and adding a transaction to `points_ledgers`.
- **XP Bar Animation**: The `PlayerCard` receives the new XP. If the total crosses the level-up threshold, a level-up visual animation is triggered.
- **QuestBoard Update**: Completed tasks reflect dynamically based on real SQLite streams.
