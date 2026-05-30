import 'package:flutter/services.dart';

/// Defines the strict MethodChannel contract for native platform widgets to request data.
class WidgetBridge {
  static const MethodChannel _channel = MethodChannel('lifeos.widgets/data');

  /// Initializes the listener for native widget RPC requests.
  static void initialize() {
    _channel.setMethodCallHandler((call) {
      switch (call.method) {
        case 'fetch_metrics':
          return _handleFetchMetrics();
        case 'trigger_sync':
          return _handleTriggerSync();
        default:
          throw MissingPluginException();
      }
    });
  }

  /// Handles requests from Android RemoteViews to populate widget layout fields
  static Future<Map<String, dynamic>> _handleFetchMetrics() async {
    // TODO: Connect to Drift DAO, count active entities, and return serialized mapping
    // Example: return {'active_habits': 3, 'pending_tasks': 5};
    return {};
  }

  /// Handles interaction intents (e.g., user tapping a sync button on the widget)
  static Future<void> _handleTriggerSync() async {
    // TODO: Trigger VaultWatcher or embedded tsnet background flush
  }
}
