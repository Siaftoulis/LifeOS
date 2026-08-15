import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'core/local_discovery_service.dart';
import 'sync_queue_file.dart';

// ponytail: package:http works on io + web (BrowserClient auto-selected), so
// one code path instead of a transport split. On web the app is served by the
// daemon itself → same-origin requests.
class ApiClient {
  String baseUrl;
  String daemonUrl;
  final http.Client _http = http.Client();
  final List<Map<String, dynamic>> _syncQueue = [];
  final ValueNotifier<int> queueLengthNotifier = ValueNotifier<int>(0);
  final ValueNotifier<String> connectionStatusNotifier = ValueNotifier<String>('LOCAL WI-FI 🏠');
  static ApiClient? _instance;
  ApiClient._internal(this.baseUrl, this.daemonUrl) {
    _evaluateConnectionStatus(daemonUrl);
  }
  factory ApiClient({String? baseUrl, String? daemonUrl}) {
    if (_instance == null) {
      _instance = ApiClient._internal(baseUrl!, daemonUrl!);
    } else if (baseUrl != null && daemonUrl != null) {
      _instance!.updateUrls(baseUrl, daemonUrl);
    }
    return _instance!;
  }
  static ApiClient get instance => _instance!;

  void _evaluateConnectionStatus(String url) {
    if (url.contains('100.64') || url.contains('100.115') || url.contains('lifeos-daemon')) {
      connectionStatusNotifier.value = 'HEADSCALE MESH 🌐';
    } else if (url.contains('192.168.') || url.contains('10.0.2') || url.contains('localhost')) {
      connectionStatusNotifier.value = 'LOCAL WI-FI 🏠';
    } else {
      connectionStatusNotifier.value = 'REMOTE CLOUD ☁️';
    }
  }

  void updateUrls(String base, String daemon) {
    baseUrl = base;
    daemonUrl = daemon;
    _evaluateConnectionStatus(daemon);
    debugPrint('ApiClient: Updated URLs base=$base daemon=$daemon');
  }

  // ponytail: queue persists to a temp file on io only; on web it lives in memory
  Future<void> _persistQueue() async {
    if (kIsWeb) return;
    try {
      final f = syncQueueFile();
      await f.writeAsString(jsonEncode(_syncQueue));
    } catch (_) {}
  }

  void _updateQueueState() { queueLengthNotifier.value = _syncQueue.length; }

  Future<void> initQueue() async {
    try {
      if (!kIsWeb) {
        final f = syncQueueFile();
        if (await f.exists()) {
          final raw = await f.readAsString();
          final decoded = jsonDecode(raw) as List;
          _syncQueue.addAll(decoded.cast<Map<String, dynamic>>());
          _updateQueueState();
          debugPrint('Local-First Engine: Restored ${_syncQueue.length} queued mutations from disk.');
        }
      }
    } catch (_) { debugPrint('Local-First Engine: No persisted queue found.'); }
    Timer.periodic(const Duration(seconds: 15), (_) => _flushQueue());
  }

  static Future<String> discoverBaseUrl() => _discover('/api/sync');

  static Future<String> discoverDaemonUrl() => _discover('/api/v1/auth/lock');

  static Future<String> _discover(String probePath) async {
    if (kIsWeb) return Uri.base.origin; // same-origin: the daemon serves the app
    final dynamicUrls = LocalDiscoveryService.instance.peersNotifier.value.map((p) => 'http://${p.address}:50051').toList();
    final urls = [
      ...dynamicUrls,
      'http://localhost:50051',
      'http://192.168.1.47:50051',
      'http://100.64.0.1:50051',      // Headscale Mesh Default GW
      'http://100.115.84.43:50051',   // Headscale Node Candidate
      'http://lifeos-daemon:50051',   // Tailnet MagicDNS Hostname
      'http://192.168.1.43:50051',
      'http://10.0.2.2:50051'
    ];
    final comp = Completer<String>(); int fails = 0;
    for (final url in urls) {
      http.post(Uri.parse('$url$probePath'), headers: {'Content-Type': 'application/json'}, body: '{}')
        .timeout(const Duration(milliseconds: 400))
        .then((res) => res.statusCode == 200 && !comp.isCompleted ? comp.complete(url) : throw Exception())
        .catchError((_) => ++fails >= urls.length && !comp.isCompleted ? comp.complete('http://localhost:50051') : null);
    }
    return comp.future.timeout(const Duration(seconds: 2), onTimeout: () => 'http://localhost:50051');
  }

  Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = AuthService.instance.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final res = await _http.post(Uri.parse('$baseUrl$endpoint'), headers: _headers, body: jsonEncode(body)).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception();
    } catch (_) {
      _syncQueue.add({'endpoint': endpoint, 'payload': body, 'timestamp': DateTime.now().toIso8601String()});
      _updateQueueState();
      await _persistQueue();
      debugPrint('Local-First Engine: Request buffered. Queue length: ${_syncQueue.length}');
      return {};
    }
  }

  Future<dynamic> postDaemon(String endpoint, Map<String, dynamic> body) async {
    final res = await _http.post(Uri.parse('$daemonUrl$endpoint'), headers: _headers, body: jsonEncode(body)).timeout(const Duration(seconds: 5));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception();
  }

  Future<dynamic> putDaemon(String endpoint, Map<String, dynamic> body) async {
    final res = await _http.put(Uri.parse('$daemonUrl$endpoint'), headers: _headers, body: jsonEncode(body)).timeout(const Duration(seconds: 5));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception();
  }

  Future<dynamic> getDaemon(String endpoint) async {
    final res = await _http.get(Uri.parse('$daemonUrl$endpoint'), headers: _headers).timeout(const Duration(seconds: 5));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception();
  }

  Future<void> _flushQueue() async {
    if (_syncQueue.isEmpty) return;
    final copy = List<Map<String, dynamic>>.from(_syncQueue); _syncQueue.clear(); _updateQueueState();
    for (final item in copy) {
      try {
        final res = await _http.post(Uri.parse('$baseUrl${item['endpoint']}'), headers: _headers, body: jsonEncode(item['payload'])).timeout(const Duration(seconds: 2));
        if (res.statusCode != 200) throw Exception();
      } catch (_) { _syncQueue.add(item); }
    }
    _updateQueueState();
    await _persistQueue();
  }
}