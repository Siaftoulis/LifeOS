import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'p2p_models.dart';
import 'local_discovery_service.dart';

class P2PTransferService {
  static final P2PTransferService instance = P2PTransferService._internal();
  P2PTransferService._internal();

  ServerSocket? _serverSocket;
  bool _isListening = false;

  // Global callback hooks for transfer confirmation prompt in UI
  Function(String senderName, String fileName, int fileSize, Socket socket)? onReceiveRequest;

  // Notifier to notify UI of file transfer progress
  final ValueNotifier<P2PProgress?> progressNotifier = ValueNotifier(null);

  // Active collaborative cursors notifier
  final ValueNotifier<Map<String, RemoteCursor>> cursorsNotifier = ValueNotifier({});

  Future<void> startServer() async {
    if (_isListening) return;
    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 4444);
      _isListening = true;
      debugPrint("P2P Socket Server listening on port 4444");

      _serverSocket!.listen((Socket clientSocket) {
        _handleIncomingConnection(clientSocket);
      });
    } catch (e) {
      debugPrint("Failed to start P2P Socket Server: $e");
    }
  }

  void _handleIncomingConnection(Socket socket) {
    StringBuffer buffer = StringBuffer();
    bool parsedHeader = false;
    
    // Track if handshake/file receiver logic takes over the socket
    StreamSubscription? sub;

    sub = socket.listen((data) async {
      if (!parsedHeader) {
        String chunk = utf8.decode(data, allowMalformed: true);
        buffer.write(chunk);
        String content = buffer.toString();
        
        if (content.contains('\n')) {
          int newlineIdx = content.indexOf('\n');
          String headerStr = content.substring(0, newlineIdx);
          
          try {
            final header = jsonDecode(headerStr) as Map<String, dynamic>;
            final type = header['type'];
            parsedHeader = true;

            if (type == 'send_request') {
              final senderName = header['senderName'] ?? 'Unknown Peer';
              final fileName = header['fileName'] ?? 'file';
              final fileSize = header['fileSize'] ?? 0;

              // Temporarily pause socket stream subscription so receiving logic can safely pull binary data
              await sub?.cancel();

              if (onReceiveRequest != null) {
                onReceiveRequest!(senderName, fileName, fileSize, socket);
              } else {
                declineFile(socket);
              }
            } else if (type == 'cursor_sync') {
              final userId = header['userId'] ?? 'Unknown User';
              final x = (header['x'] as num?)?.toDouble() ?? 0.0;
              final y = (header['y'] as num?)?.toDouble() ?? 0.0;
              final filePath = header['filePath'] ?? '';

              _handleCursorSync(userId, x, y, filePath);
              await sub?.cancel();
              socket.close();
            } else {
              await sub?.cancel();
              socket.close();
            }
          } catch (e) {
            debugPrint("Error parsing incoming request header: $e");
            await sub?.cancel();
            socket.close();
          }
        }
      }
    }, onError: (e) {
      debugPrint("P2P socket receive error: $e");
      progressNotifier.value = null;
    });
  }

  void _handleCursorSync(String userId, double x, double y, String filePath) {
    final Map<String, RemoteCursor> current = Map.from(cursorsNotifier.value);
    current[userId] = RemoteCursor(
      userId: userId,
      x: x,
      y: y,
      filePath: filePath,
      timestamp: DateTime.now(),
    );
    cursorsNotifier.value = current;
  }

  Future<void> broadcastCursor(String userId, double x, double y, String filePath) async {
    final peers = LocalDiscoveryService.instance.peersNotifier.value;
    for (final peer in peers) {
      try {
        final socket = await Socket.connect(peer.address, peer.port, timeout: const Duration(milliseconds: 300));
        socket.write(jsonEncode({
          'type': 'cursor_sync',
          'userId': userId,
          'x': x,
          'y': y,
          'filePath': filePath,
        }) + '\n');
        await socket.flush();
        socket.close();
      } catch (_) {
        // Silently skip offline or unreachable peers
      }
    }
  }

  Future<void> sendFile(String peerAddress, int peerPort, File file, String fileName) async {
    try {
      final totalBytes = file.lengthSync();
      progressNotifier.value = P2PProgress(
        fileName: fileName,
        bytesTransferred: 0,
        totalBytes: totalBytes,
        isSender: true,
        speedMBs: 0,
        isCompleted: false,
      );

      final socket = await Socket.connect(peerAddress, peerPort, timeout: const Duration(seconds: 4));
      
      final header = {
        'type': 'send_request',
        'senderName': 'Local Device',
        'fileName': fileName,
        'fileSize': totalBytes,
      };

      socket.write(jsonEncode(header) + '\n');
      await socket.flush();

      Completer<bool> handshakeCompleter = Completer();
      StringBuffer responseBuffer = StringBuffer();
      
      StreamSubscription? sub;
      sub = socket.listen((data) {
        responseBuffer.write(utf8.decode(data, allowMalformed: true));
        final str = responseBuffer.toString();
        if (str.contains('\n')) {
          final line = str.split('\n').first;
          try {
            final resp = jsonDecode(line);
            if (resp['status'] == 'accepted') {
              handshakeCompleter.complete(true);
            } else {
              handshakeCompleter.complete(false);
            }
          } catch (_) {
            handshakeCompleter.complete(false);
          }
        }
      }, onError: (_) {
        if (!handshakeCompleter.isCompleted) handshakeCompleter.complete(false);
      });

      final accepted = await handshakeCompleter.future.timeout(
        const Duration(seconds: 10), 
        onTimeout: () => false
      );
      
      await sub.cancel();

      if (!accepted) {
        progressNotifier.value = null;
        socket.close();
        return;
      }

      final fileStream = file.openRead();
      int sent = 0;
      final startTime = DateTime.now();

      await for (final chunk in fileStream) {
        socket.add(chunk);
        sent += chunk.length;

        final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
        final speed = elapsedMs > 0 ? (sent / (1024.0 * 1024.0)) / (elapsedMs / 1000.0) : 0.0;

        progressNotifier.value = P2PProgress(
          fileName: fileName,
          bytesTransferred: sent,
          totalBytes: totalBytes,
          isSender: true,
          speedMBs: speed,
          isCompleted: false,
        );
      }

      await socket.flush();
      progressNotifier.value = P2PProgress(
        fileName: fileName,
        bytesTransferred: totalBytes,
        totalBytes: totalBytes,
        isSender: true,
        speedMBs: 0,
        isCompleted: true,
      );

      await Future.delayed(const Duration(milliseconds: 800));
      progressNotifier.value = null;
      socket.close();
    } catch (e) {
      debugPrint("P2P file send error: $e");
      progressNotifier.value = null;
    }
  }

  Future<void> acceptFile(Socket socket, String fileName, int fileSize) async {
    try {
      socket.write(jsonEncode({'status': 'accepted'}) + '\n');
      await socket.flush();

      final dir = Directory('vault/Media');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      final file = File('${dir.path}/$fileName');
      final sink = file.openWrite();

      int received = 0;
      final startTime = DateTime.now();

      progressNotifier.value = P2PProgress(
        fileName: fileName,
        bytesTransferred: 0,
        totalBytes: fileSize,
        isSender: false,
        speedMBs: 0,
        isCompleted: false,
      );

      Completer<void> doneCompleter = Completer();
      
      socket.listen((chunk) {
        sink.add(chunk);
        received += chunk.length;

        final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
        final speed = elapsedMs > 0 ? (received / (1024.0 * 1024.0)) / (elapsedMs / 1000.0) : 0.0;

        progressNotifier.value = P2PProgress(
          fileName: fileName,
          bytesTransferred: received,
          totalBytes: fileSize,
          isSender: false,
          speedMBs: speed,
          isCompleted: false,
        );

        if (received >= fileSize) {
          if (!doneCompleter.isCompleted) doneCompleter.complete();
        }
      }, onError: (e) {
        if (!doneCompleter.isCompleted) doneCompleter.completeError(e);
      }, onDone: () {
        if (!doneCompleter.isCompleted) doneCompleter.complete();
      });

      await doneCompleter.future;
      await sink.flush();
      await sink.close();

      progressNotifier.value = P2PProgress(
        fileName: fileName,
        bytesTransferred: fileSize,
        totalBytes: fileSize,
        isSender: false,
        speedMBs: 0,
        isCompleted: true,
      );

      await Future.delayed(const Duration(milliseconds: 800));
      progressNotifier.value = null;
      socket.close();
    } catch (e) {
      debugPrint("P2P file accept error: $e");
      progressNotifier.value = null;
      socket.close();
    }
  }

  void declineFile(Socket socket) {
    try {
      socket.write(jsonEncode({'status': 'declined'}) + '\n');
      socket.close();
    } catch (_) {}
  }

  Future<void> stopServer() async {
    if (_serverSocket != null) {
      await _serverSocket!.close();
      _serverSocket = null;
    }
    _isListening = false;
  }
}
