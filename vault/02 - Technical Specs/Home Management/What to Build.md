# What to Build | Home Management

This document specifies the exact SQLite schemas, REST API paths, and Flutter widget components to build for the Home Management smart home dashboard.

---

## 1. Database Architecture (SQLite / Drift)

Three tables must be defined in the SQLite cache layer to support smart appliances status registry, sensor logs, and schedules.

```sql
-- Schema for Smart Devices Registry
CREATE TABLE IF NOT EXISTS smart_devices (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL, -- 'LIGHT', 'SWITCH', 'THERMOSTAT', 'APPLIANCE'
    state TEXT NOT NULL, -- 'ON', 'OFF', 'UNKNOWN'
    room TEXT,
    last_updated INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0
);

-- Schema for Environment Logs
CREATE TABLE IF NOT EXISTS environment_logs (
    id TEXT PRIMARY KEY,
    sensor_id TEXT NOT NULL,
    temperature REAL,
    humidity REAL,
    timestamp INTEGER NOT NULL,
    is_dirty INTEGER DEFAULT 0
);

-- Schema for Device Schedules
CREATE TABLE IF NOT EXISTS device_schedules (
    id TEXT PRIMARY KEY,
    device_id TEXT NOT NULL,
    action TEXT NOT NULL, -- 'TURN_ON', 'TURN_OFF'
    cron_expression TEXT NOT NULL,
    is_dirty INTEGER DEFAULT 0,
    FOREIGN KEY(device_id) REFERENCES smart_devices(id) ON DELETE CASCADE
);
```

---

## 2. API Specifications (Go Backend Daemon)

The host daemon routes WebSocket payloads to Home Assistant, intercepts remote sensor uploads, and launches automated triggers.

### REST Endpoints
- **List & Control Devices:**
  - `GET /api/v1/home/devices`
  - Response: `JSON` list of registered lights, switches, and lock entities.
- **Toggle Device State:**
  - `POST /api/v1/home/devices/toggle`
  - Payload: `{"device_id": "light.living_room", "state": "ON"}`
  - Response: Updated entity properties.
- **Sensor Telemetry Report:**
  - `POST /api/v1/home/sensors/report`
  - Payload: `{"sensor_id": "rpi_kitchen", "temperature": 22.5, "humidity": 45.0}`
  - Response: Acknowledgment status.

---

## 3. UI Component Registry (Flutter Client)

All widgets are declared inside `client/lib/presentation/widgets/` or plugins:

- **`SmartHomeDashboard`:** Main screen displays room filters, environmental temperature streams, and quick-access schedules.
- **`DeviceGridToggle`:** Grid of active switch components showcasing status changes, neon state glows, and touch gestures.
- **`SensorLogsPanel`:** Inline sensor logs panel presenting dynamic charts of temperature metrics over 24-hour cycles.
