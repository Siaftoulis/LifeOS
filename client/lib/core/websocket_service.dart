import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final String serverUrl;
  final void Function(Map<String, dynamic> data) onMessageReceived;

  WebSocketService({required this.serverUrl, required this.onMessageReceived});

  void connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(serverUrl));
      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            onMessageReceived(data);
          } catch (e) {
            debugPrint("WebSocket parsing error: $e");
          }
        },
        onError: (error) {
          debugPrint("WebSocket error: $error");
          _reconnect();
        },
        onDone: () {
          debugPrint("WebSocket closed");
          _reconnect();
        },
      );
    } catch (e) {
      debugPrint("WebSocket connect error: $e");
      _reconnect();
    }
  }

  void _reconnect() {
    Future.delayed(const Duration(seconds: 5), () {
      if (_channel == null || _channel?.closeCode != null) {
        connect();
      }
    });
  }

  void send(Map<String, dynamic> data) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void dispose() {
    _channel?.sink.close();
  }
}
