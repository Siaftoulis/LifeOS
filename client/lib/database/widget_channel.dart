import 'package:flutter/services.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'dart:convert';
import 'dart:async';

class WidgetChannel {
  static const MethodChannel _channel = MethodChannel('lifeos.widgets/data');
  static Timer? _debounceTimer;

  static void initialize() {
    _channel.setMethodCallHandler((call) async {
      return null;
    });
  }

  /// Broadcasts payload out to native layer and in-memory IPC desktop sub-windows
  static Future<void> pushPayload(Map<String, dynamic> data) async {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        // Native Android Bridge
        await _channel.invokeMethod('update_widget', data);
        
        // Windows 11 Desktop In-Memory IPC Bus
        final subWindowIds = await DesktopMultiWindow.getAllSubWindowIds();
        final jsonPayload = jsonEncode(data);
        for (final windowId in subWindowIds) {
          await DesktopMultiWindow.invokeMethod(windowId, 'update_metrics', jsonPayload);
        }
      } catch (e) {
        print('Widget Channel Error: $e');
      }
    });
  }
}
