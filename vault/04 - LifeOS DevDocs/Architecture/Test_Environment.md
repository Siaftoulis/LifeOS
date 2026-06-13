# Test Environment Architecture

> [!NOTE]
> **Home:** [[04 - LifeOS DevDocs/Home|Home]]


## 1. Wireless ADB Targeting
For ultra-fast debug iterations without physical USB tethers:
*   **Pairing:** Execute `adb pair <IP>:<PORT>` using the device's native Developer Options Wireless Debugging settings.
*   **Connection:** Execute `adb connect <IP>:<PORT>` to bridge the Android target. The mobile device will now securely appear in the `flutter devices` index.

## 2. Over-The-Air (OTA) QR Pipeline
To deploy profiled, detached Android binaries to remote local targets seamlessly:
*   **Execution:** Triggering the `.agent/serve_apk.ps1` script launches a localized `flutter build apk --profile`.
*   **Hosting:** A lightweight background Python HTTP server (`python -m http.server`) spins up, natively anchoring to the `/build/` output directory.
*   **QR Distribution:** The script resolves the host's active LAN IP, dynamically computing a direct download URI. An ASCII QR code is rendered via shell stdout. Scanning this code on the target device initiates the binary sideloading over the local network mesh instantly.
