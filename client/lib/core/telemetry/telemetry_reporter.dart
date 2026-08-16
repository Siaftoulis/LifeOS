import 'dart:async';
import 'dart:convert';
import '../../api_client.dart';
import 'telemetry_queue_file.dart';

/// Client-side activity log: "something happened" facts, encoded so a casual
/// read of the queue file shows nothing. Sent to the daemon in small packets
/// (max 5 at a time) every 30s or on overflow; the daemon decodes, validates
/// against its rules and awards points itself — the client never sends point
/// amounts, so there is nothing to forge.
///
/// ponytail: XOR+base64 obfuscation, not security. Server-side rules + dedup
/// are the real integrity boundary; this only stops shoulder-surfing the log.
class TelemetryReporter {
  static final TelemetryReporter instance = TelemetryReporter._();

  TelemetryReporter._() {
    _restore();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => flush());
  }

  static const int _maxPacket = 5;
  static const String _key = 'lifeos-tel-2026-x';

  final List<String> _queue = [];
  Timer? _timer;

  /// Records one activity fact. Never include point values — the server
  /// decides what anything is worth.
  void track(String module, String action, [Map<String, dynamic> data = const {}]) {
    final wire = jsonEncode({
      'module': module,
      'action': action,
      'data': data,
      'ts': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
    _queue.add(_encode(wire));
    _persist();
    if (_queue.length >= _maxPacket) flush(); // small packets, never a dump
  }

  Future<void> flush() async {
    if (_queue.isEmpty) return;
    final chunk = _queue.take(_maxPacket).toList();
    try {
      await ApiClient.instance.postDaemon('/api/v1/telemetry/batch', {'packet': chunk});
      _queue.removeRange(0, chunk.length);
      _persist();
    } catch (_) {
      // daemon offline: packet stays queued for the next flush
    }
  }

  /// Records one activity and flushes immediately, returning the daemon's
  /// response ({awarded, balance}) for instant UI feedback. Null if offline.
  Future<Map<String, dynamic>?> trackAndFlush(
      String module, String action, [Map<String, dynamic> data = const {}]) async {
    track(module, action, data);
    try {
      final chunk = _queue.take(_maxPacket).toList();
      final res = await ApiClient.instance
          .postDaemon('/api/v1/telemetry/batch', {'packet': chunk});
      _queue.removeRange(0, chunk.length);
      _persist();
      return res is Map<String, dynamic> ? res : null;
    } catch (_) {
      return null;
    }
  }

  static String _encode(String plain) {
    final bytes = utf8.encode(plain);
    final key = utf8.encode(_key);
    final xored = List<int>.generate(bytes.length, (i) => bytes[i] ^ key[i % key.length]);
    return base64Url.encode(xored);
  }

  dynamic get _file => telemetryQueueFile();

  Future<void> _restore() async {
    try {
      final f = _file;
      if (f != null && await f.exists()) {
        _queue.addAll((jsonDecode(await f.readAsString()) as List).cast<String>());
      }
    } catch (_) {}
  }

  void _persist() {
    try {
      _file?.writeAsString(jsonEncode(_queue));
    } catch (_) {}
  }

  void dispose() {
    _timer?.cancel();
  }
}