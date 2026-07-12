import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../api_client.dart';
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

  bool _isConnected = false;

  void connect() {
    if (_isConnected) return;
    
    try {
      final baseUrl = ApiClient.instance.baseUrl;
      if (baseUrl.isEmpty) return;
      
      final wsUrl = baseUrl.replaceFirst('http', 'ws').replaceFirst('https', 'wss') + '/sync';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channel!.ready.then((_) {
        debugPrint("WebsocketSyncService connection ready");
      }).catchError((err) {
        debugPrint("WebsocketSyncService channel.ready error: $err");
      });
      _isConnected = true;
      debugPrint("WebsocketSyncService connected to $wsUrl");

      _subscription = _channel?.stream.listen(
        (data) {
          try {
            final payload = jsonDecode(data);
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
          _isConnected = false;
          debugPrint("WebsocketSyncService disconnected");
          _reconnect();
        },
        onError: (err) {
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
    Future.delayed(const Duration(seconds: 5), () {
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
    if (!_isConnected || _channel == null) return;
    final msg = jsonEncode({
      'type': 'cursor_sync',
      'userId': userId,
      'x': x,
      'y': y,
      'filePath': filePath,
    });
    _channel!.sink.add(msg);
  }

  void broadcastTextDelta(String userId, String filePath, String textContent, int offset) {
    if (!_isConnected || _channel == null) return;
    final msg = jsonEncode({
      'type': 'text_delta',
      'userId': userId,
      'filePath': filePath,
      'textContent': textContent,
      'offset': offset,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    _channel!.sink.add(msg);
  }

  void broadcastCreateNode(String userId, String parentPath, String name, bool isDirectory) {
    if (!_isConnected || _channel == null) return;
    _channel!.sink.add(jsonEncode({
      'type': 'create_node',
      'userId': userId,
      'parentPath': parentPath,
      'name': name,
      'isDirectory': isDirectory,
    }));
  }

  void broadcastDeleteNode(String userId, String relativePath) {
    if (!_isConnected || _channel == null) return;
    _channel!.sink.add(jsonEncode({
      'type': 'delete_node',
      'userId': userId,
      'relativePath': relativePath,
    }));
  }

  void broadcastRenameNode(String userId, String oldRelativePath, String newName) {
    if (!_isConnected || _channel == null) return;
    _channel!.sink.add(jsonEncode({
      'type': 'rename_node',
      'userId': userId,
      'oldRelativePath': oldRelativePath,
      'newName': newName,
    }));
  }

  void broadcastMoveNode(String userId, String oldRelativePath, String targetParentRelativePath) {
    if (!_isConnected || _channel == null) return;
    _channel!.sink.add(jsonEncode({
      'type': 'move_node',
      'userId': userId,
      'oldRelativePath': oldRelativePath,
      'targetParentRelativePath': targetParentRelativePath,
    }));
  }

  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _isConnected = false;
  }
}
