import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api_client.dart';
import '../auth_service.dart';
import 'websocket_service.dart';

/// EventHub — the receiving end of the ecosystem bus. The daemon relays
/// every fact over WS /api/v1/events; widgets subscribe to what they care
/// about. Live, no polling.
class EventHub {
  static final EventHub instance = EventHub._();
  EventHub._();

  final StreamController<Map<String, dynamic>> _controller =
      StreamController.broadcast();
  // ponytail: the WS service needs a rooted reference for its reconnect
  // loop; the hub never reads it again. ignore: unused_field
  WebSocketService? _ws;

  void dispose() {
    _ws?.dispose();
    _controller.close();
  }

  /// Every relayed event: {'id', 'at', 'topic', 'user_id', 'payload'}.
  Stream<Map<String, dynamic>> get events => _controller.stream;

  /// Events of one topic, e.g. 'points:balance-change'.
  Stream<Map<String, dynamic>> on(String topic) =>
      _controller.stream.where((e) => e['topic'] == topic);

  void connect() {
    if (kIsWeb) return; // ponytail: portal served same-origin; push is for native
    final token = AuthService.instance.token;
    if (token == null || token.isEmpty) return;
    final scheme = ApiClient.instance.daemonUrl.startsWith('https') ? 'wss' : 'ws';
    final base = ApiClient.instance.daemonUrl.replaceFirst(RegExp(r'^https?://'), '$scheme://');
    _ws = WebSocketService(
      serverUrl: '$base/api/v1/events?token=$token',
      onMessageReceived: (data) {
        if (data['topic'] != null) {
          _controller.add(Map<String, dynamic>.from(data));
        }
      },
    )..connect();
  }
}