# Next Steps | Home Management

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Home Management|Home Management]]

## 1. Backend Implementation (Beyond Stubs)
- **Smart Device Protocols:** Replace the stubs with actual local IoT protocol integrations. The Go Daemon should implement MQTT client logic or local HTTP polling (e.g., for Shelly relays or local Tuya devices) to control smart plugs without relying on cloud APIs.
- **Sensor Telemetry:** Integrate an endpoint to receive temperature/humidity webhooks from local ESP32 or Zigbee sensors.

## 2. Data Interconnectivity & Relationships
- **Link to Point Star System:** As previously implemented, dropping below 0 points triggers the `TV Lockout` smart plug through this module's API.
- **Link to CHTM:** Home maintenance tasks (e.g., "Change AC filters") generated here should mirror to the central Calendar Habit Task Manager.

## 3. Open Design Questions
1. Should we run a full Home Assistant instance locally and have the Go Daemon just act as a proxy, or do you want the Go Daemon to be the *actual* IoT orchestrator?
2. How should we handle IP camera streams (RTSP) in the Flutter UI?
