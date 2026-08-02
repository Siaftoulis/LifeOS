import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../api_client.dart';
import '../../database/preferences_service.dart';
import '../p2p_models.dart'; // Reusing RemoteCursor
import 'zen_sync_service.dart';

class WebsocketSyncService {
  static final WebsocketSyncService instance = WebsocketSyncService._internal();
  WebsocketSyncService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  
  final ValueNotifier<Map<String, RemoteCursor>> cursorsNotifier = ValueNotifier({});
  
  // Stream to let UI listen for text changes from others
  final _textDeltaController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onTextDelta => _textDeltaController.stream;

  final _rawMessageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onRawMessage => _rawMessageController.stream;

  bool _isConnected = false;
  bool _reconnecting = false;

  void sendRaw(String message) {
    if (!_isConnected || _channel == null) return;
    try {
      _channel!.sink.add(message);
    } catch (e) {
      debugPrint('WebsocketSyncService sendRaw dropped: $e');
    }
  }

  void connect() {
    if (_isConnected) return;
    
    try {
      _subscription?.cancel();
      _channel?.sink.close();
      _channel = null;

      final daemonUrl = ApiClient.instance.daemonUrl;
      if (daemonUrl.isEmpty) return;
      
      // The websocket endpoint lives on the sync hub (:8080), not the daemon (:50051).
      final hubUrl = daemonUrl.endsWith(':50051')
          ? '${daemonUrl.substring(0, daemonUrl.length - ':50051'.length)}:8080'
          : daemonUrl;

      // ponytail: base64 JSON wrapper for binary Yjs updates, hub stays stateless
      final token = PreferencesService.authToken.value;
      final endpoint = token.isNotEmpty ? '/ws?token=$token' : '/ws';
      final wsUrl = hubUrl.replaceFirst('http', 'ws').replaceFirst('https', 'wss') + endpoint;
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      final channel = _channel;
      // ponytail: _isConnected flips only when ready resolves; sending on a failed
      // channel throws and would kill editor keystrokes through the root listener.
      channel!.ready.then((_) {
        if (!identical(channel, _channel)) return;
        _isConnected = true;
        debugPrint("WebsocketSyncService connection ready: $wsUrl");
      }).catchError((err) {
        if (!identical(channel, _channel)) return;
        _isConnected = false;
        debugPrint("WebsocketSyncService channel.ready error: $err");
        _reconnect();
      });

      _subscription = channel.stream.listen(
        (data) {
          try {
            final payload = jsonDecode(data);
            if (payload is Map<String, dynamic>) {
              _rawMessageController.add(payload);
            }
            final type = payload['type'];
            
            if (type == 'cursor_sync') {
              _handleCursorSync(payload);
            } else if (type == 'text_delta') {
              _textDeltaController.add(payload);
            } else if (type == 'create_node') {
              final userId = payload['userId'] ?? '';
              if (userId != 'User_${Platform.localHostname}') {
                final parentPath = payload['parentPath'] ?? '';
                final name = payload['name'] ?? '';
                final isDirectory = payload['isDirectory'] ?? false;
                ZenSyncService.instance.createNode(parentPath, name, isDirectory, broadcast: false);
              }
            } else if (type == 'delete_node') {
              final userId = payload['userId'] ?? '';
              if (userId != 'User_${Platform.localHostname}') {
                final relativePath = payload['relativePath'] ?? '';
                ZenSyncService.instance.deleteNode(relativePath, broadcast: false);
              }
            } else if (type == 'rename_node') {
              final userId = payload['userId'] ?? '';
              if (userId != 'User_${Platform.localHostname}') {
                final oldRelativePath = payload['oldRelativePath'] ?? '';
                final newName = payload['newName'] ?? '';
                ZenSyncService.instance.renameNode(oldRelativePath, newName, broadcast: false);
              }
            } else if (type == 'move_node') {
              final userId = payload['userId'] ?? '';
              if (userId != 'User_${Platform.localHostname}') {
                final oldRelativePath = payload['oldRelativePath'] ?? '';
                final targetParentRelativePath = payload['targetParentRelativePath'] ?? '';
                ZenSyncService.instance.moveNode(oldRelativePath, targetParentRelativePath, broadcast: false);
              }
            }
          } catch (e) {
            debugPrint("WebsocketSyncService parse error: $e");
          }
        },
        onDone: () {
          if (!identical(channel, _channel)) return;
          _isConnected = false;
          debugPrint("WebsocketSyncService disconnected");
          _reconnect();
        },
        onError: (err) {
          if (!identical(channel, _channel)) return;
          _isConnected = false;
          debugPrint("WebsocketSyncService error: $err");
          _reconnect();
        }
      );
    } catch (e) {
      _isConnected = false;
      debugPrint("WebsocketSyncService connection failed: $e");
      _reconnect();
    }
  }

  void _reconnect() {
    if (_reconnecting) return;
    _reconnecting = true;
    Future.delayed(const Duration(seconds: 5), () {
      _reconnecting = false;
      if (!_isConnected) connect();
    });
  }

  void _handleCursorSync(Map<String, dynamic> payload) {
    final userId = payload['userId'] ?? 'Unknown User';
    final x = (payload['x'] as num?)?.toDouble() ?? 0.0;
    final y = (payload['y'] as num?)?.toDouble() ?? 0.0;
    final filePath = payload['filePath'] ?? '';

    final Map<String, RemoteCursor> current = Map.from(cursorsNotifier.value);
    current[userId] = RemoteCursor(
      userId: userId,
      x: x,
      y: y,
      filePath: filePath,
      timestamp: DateTime.now(),
    );
    
    // Prune old cursors (e.g., > 10 seconds inactive)
    current.removeWhere((key, cursor) => DateTime.now().difference(cursor.timestamp).inSeconds > 10);
    
    cursorsNotifier.value = current;
  }

  void broadcastCursor(String userId, double x, double y, String filePath) {
    _safeSend(jsonEncode({
      'type': 'cursor_sync',
      'userId': userId,
      'x': x,
      'y': y,
      'filePath': filePath,
    }));
  }

  void broadcastTextDelta(String userId, String filePath, String textContent, int offset) {
    _safeSend(jsonEncode({
      'type': 'text_delta',
      'userId': userId,
      'filePath': filePath,
      'textContent': textContent,
      'offset': offset,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }));
  }

  void broadcastCreateNode(String userId, String parentPath, String name, bool isDirectory) {
    _safeSend(jsonEncode({
      'type': 'create_node',
      'userId': userId,
      'parentPath': parentPath,
      'name': name,
      'isDirectory': isDirectory,
    }));
  }

  void broadcastDeleteNode(String userId, String relativePath) {
    _safeSend(jsonEncode({
      'type': 'delete_node',
      'userId': userId,
      'relativePath': relativePath,
    }));
  }

  void broadcastRenameNode(String userId, String oldRelativePath, String newName) {
    _safeSend(jsonEncode({
      'type': 'rename_node',
      'userId': userId,
      'oldRelativePath': oldRelativePath,
      'newName': newName,
    }));
  }

  void broadcastMoveNode(String userId, String oldRelativePath, String targetParentRelativePath) {
    _safeSend(jsonEncode({
      'type': 'move_node',
      'userId': userId,
      'oldRelativePath': oldRelativePath,
      'targetParentRelativePath': targetParentRelativePath,
    }));
  }

  void _safeSend(String message) {
    if (!_isConnected || _channel == null) return;
    try {
      _channel!.sink.add(message);
    } catch (e) {
      debugPrint('WebsocketSyncService message dropped: $e');
    }
  }

  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _isConnected = false;
  }
}
