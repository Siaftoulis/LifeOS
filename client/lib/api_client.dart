import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'core/local_discovery_service.dart';

class ApiClient {
  String baseUrl;
  String daemonUrl;
  final HttpClient _http = HttpClient()..connectionTimeout = const Duration(seconds: 2);
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

  File _getLogFile() => File('${Directory.systemTemp.path}/sync_queue.json');
  void _updateQueueState() { queueLengthNotifier.value = _syncQueue.length; }

  Future<void> initQueue() async {
    try {
      final f = _getLogFile();
      if (await f.exists()) {
        final raw = await f.readAsString();
        final decoded = jsonDecode(raw) as List;
        _syncQueue.addAll(decoded.cast<Map<String, dynamic>>());
        _updateQueueState();
        debugPrint('Local-First Engine: Restored ${_syncQueue.length} queued mutations from disk.');
      }
    } catch (_) { debugPrint('Local-First Engine: No persisted queue found.'); }
    Timer.periodic(const Duration(seconds: 15), (_) => _flushQueue());
  }

  Future<void> _persistQueue() async {
    try { await _getLogFile().writeAsString(jsonEncode(_syncQueue)); } catch (_) {}
  }

  static Future<String> discoverBaseUrl() async {
    final dynamicUrls = LocalDiscoveryService.instance.peersNotifier.value.map((p) => 'http://${p.address}:50051').toList();
    final urls = [
      ...dynamicUrls,
      'http://192.168.1.47:50051',
      'http://100.64.0.1:50051',      // Headscale Mesh Default GW
      'http://100.115.84.43:50051',   // Headscale Node Candidate
      'http://lifeos-daemon:50051',   // Tailnet MagicDNS Hostname
      'http://192.168.1.43:50051',
      'http://10.0.2.2:50051',
      'http://localhost:50051'
    ];
    final comp = Completer<String>(); int fails = 0;
    for (final url in urls) {
      HttpClient().postUrl(Uri.parse('$url/api/sync')).then((req) { req.headers.contentType = ContentType.json; req.write('{}'); return req.close(); })
        .then((res) => res.statusCode == 200 && !comp.isCompleted ? comp.complete(url) : throw Exception())
        .catchError((_) => ++fails >= urls.length && !comp.isCompleted ? comp.complete('http://192.168.1.47:50051') : null);
    }
    return comp.future.timeout(const Duration(seconds: 2), onTimeout: () => 'http://192.168.1.47:50051');
  }

  static Future<String> discoverDaemonUrl() async {
    final dynamicUrls = LocalDiscoveryService.instance.peersNotifier.value.map((p) => 'http://${p.address}:50051').toList();
    final urls = [
      ...dynamicUrls,
      'http://192.168.1.47:50051',
      'http://100.64.0.1:50051',      // Headscale Mesh Default GW
      'http://100.115.84.43:50051',   // Headscale Node Candidate
      'http://lifeos-daemon:50051',   // Tailnet MagicDNS Hostname
      'http://192.168.1.43:50051',
      'http://10.0.2.2:50051',
      'http://localhost:50051'
    ];
    final comp = Completer<String>(); int fails = 0;
    for (final url in urls) {
      HttpClient().postUrl(Uri.parse('$url/api/v1/auth/lock')).then((req) { req.headers.contentType = ContentType.json; req.write('{}'); return req.close(); })
        .then((res) => res.statusCode == 200 && !comp.isCompleted ? comp.complete(url) : throw Exception())
        .catchError((_) => ++fails >= urls.length && !comp.isCompleted ? comp.complete('http://192.168.1.47:50051') : null);
    }
    return comp.future.timeout(const Duration(seconds: 2), onTimeout: () => 'http://192.168.1.47:50051');
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final req = await _http.postUrl(Uri.parse('$baseUrl$endpoint'));
      req.headers.contentType = ContentType.json;
      final token = AuthService.instance.token;
      if (token != null && token.isNotEmpty) {
        req.headers.set('Authorization', 'Bearer $token');
      }
      req.add(utf8.encode(jsonEncode(body)));
      final res = await req.close().timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) return jsonDecode(await res.transform(utf8.decoder).join());
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
    final req = await _http.postUrl(Uri.parse('$daemonUrl$endpoint'));
    req.headers.contentType = ContentType.json;
    final token = AuthService.instance.token;
    if (token != null && token.isNotEmpty) {
      req.headers.set('Authorization', 'Bearer $token');
    }
    req.add(utf8.encode(jsonEncode(body)));
    final res = await req.close().timeout(const Duration(seconds: 5));
    if (res.statusCode == 200) return jsonDecode(await res.transform(utf8.decoder).join());
    throw Exception();
  }

  Future<dynamic> putDaemon(String endpoint, Map<String, dynamic> body) async {
    final req = await _http.putUrl(Uri.parse('$daemonUrl$endpoint'));
    req.headers.contentType = ContentType.json;
    final token = AuthService.instance.token;
    if (token != null && token.isNotEmpty) {
      req.headers.set('Authorization', 'Bearer $token');
    }
    req.add(utf8.encode(jsonEncode(body)));
    final res = await req.close().timeout(const Duration(seconds: 5));
    if (res.statusCode == 200) return jsonDecode(await res.transform(utf8.decoder).join());
    throw Exception();
  }

  Future<dynamic> getDaemon(String endpoint) async {
    final req = await _http.getUrl(Uri.parse('$daemonUrl$endpoint'));
    final token = AuthService.instance.token;
    if (token != null && token.isNotEmpty) {
      req.headers.set('Authorization', 'Bearer $token');
    }
    final res = await req.close().timeout(const Duration(seconds: 5));
    if (res.statusCode == 200) return jsonDecode(await res.transform(utf8.decoder).join());
    throw Exception();
  }

  Future<void> _flushQueue() async {
    if (_syncQueue.isEmpty) return;
    final copy = List<Map<String, dynamic>>.from(_syncQueue); _syncQueue.clear(); _updateQueueState();
    for (final item in copy) {
      try {
        final req = await _http.postUrl(Uri.parse('$baseUrl${item['endpoint']}'));
        req.headers.contentType = ContentType.json;
        final token = AuthService.instance.token;
        if (token != null && token.isNotEmpty) {
          req.headers.set('Authorization', 'Bearer $token');
        }
        req.add(utf8.encode(jsonEncode(item['payload'])));
        if ((await req.close().timeout(const Duration(seconds: 2))).statusCode != 200) throw Exception();
      } catch (_) { _syncQueue.add(item); }
    }
    _updateQueueState();
    await _persistQueue();
  }
}
