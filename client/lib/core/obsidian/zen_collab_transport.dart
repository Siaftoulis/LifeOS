import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../api_client.dart';
import '../../auth_service.dart';

/// WebSocket transport to the Go daemon collab hub (/api/markdown/collab).
/// One connection per document; JWT from the session is passed as a query
/// param since browser WebSocket can't set Authorization headers.
/// WebSocketChannel.connect works on io AND web (browser native WebSocket).
class ZenCollabTransport {
  static final ZenCollabTransport instance = ZenCollabTransport._internal();
  ZenCollabTransport._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  String? _room;
  bool _connected = false;
  bool _reconnecting = false;
  Timer? _reconnectTimer;

  final _incomingController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onMessage => _incomingController.stream;
  bool get isConnected => _connected;

  Future<void> connect(String room) async {
    if (_room == room && _connected) return;
    await disconnect();

    _room = room;
    try {
      final daemon = ApiClient.instance.daemonUrl;
      final token = AuthService.instance.token ?? '';
      final base = daemon.replaceFirst('http', 'ws').replaceFirst('https', 'wss');
      final url = '$base/api/markdown/collab?doc_id=${Uri.encodeQueryComponent(room)}&token=$token';
      _channel = WebSocketChannel.connect(Uri.parse(url));
      final channel = _channel!;

      channel.ready.then((_) {
        if (!identical(channel, _channel)) return;
        _connected = true;
        debugPrint('[ZenCollab] connected to room $room');
      }).catchError((err) {
        if (!identical(channel, _channel)) return;
        _connected = false;
        debugPrint('[ZenCollab] connect error: $err');
        _scheduleReconnect();
      });

      _sub = channel.stream.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String);
            if (msg is Map<String, dynamic>) {
              _incomingController.add(msg);
            }
          } catch (e) {
            debugPrint('[ZenCollab] parse error: $e');
          }
        },
        onDone: () {
          if (!identical(channel, _channel)) return;
          _connected = false;
          debugPrint('[ZenCollab] disconnected from $room');
          _scheduleReconnect();
        },
        onError: (err) {
          if (!identical(channel, _channel)) return;
          _connected = false;
          debugPrint('[ZenCollab] stream error: $err');
          _scheduleReconnect();
        },
      );
    } catch (e) {
      _connected = false;
      debugPrint('[ZenCollab] connect failed: $e');
      _scheduleReconnect();
    }
  }

  void send(Map<String, dynamic> message) {
    if (!_connected || _channel == null) return;
    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      debugPrint('[ZenCollab] send dropped: $e');
    }
  }

  void _scheduleReconnect() {
    if (_reconnecting) return;
    _reconnecting = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      _reconnecting = false;
      if (!_connected && _room != null) connect(_room!);
    });
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    await _sub?.cancel();
    _sub = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _connected = false;
  }

  void dispose() {
    disconnect();
    _incomingController.close();
  }
}
