import 'dart:async';
import 'dart:convert';
import 'dart:io';

class ApiClient {
  final String baseUrl;
  final HttpClient _http = HttpClient()..connectionTimeout = const Duration(seconds: 2);
  ApiClient({required this.baseUrl});

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> payload, {int retries = 3}) async {
    int delayMs = 500;
    for (int i = 0; i < retries; i++) {
      try {
        final req = await _http.postUrl(Uri.parse('$baseUrl$endpoint'));
        req.headers.contentType = ContentType.json;
        req.add(utf8.encode(jsonEncode(payload)));
        
        final res = await req.close().timeout(const Duration(seconds: 2));
        if (res.statusCode == 200) {
          final body = await res.transform(utf8.decoder).join();
          return jsonDecode(body);
        }
        throw HttpException("Daemon rejected RPC: HTTP ${res.statusCode}");
      } catch (e) {
        if (i == retries - 1) throw Exception("Network failure after $retries attempts: $e");
        await Future.delayed(Duration(milliseconds: delayMs));
        delayMs *= 2; // Exponential backoff scaling
      }
    }
    throw Exception("Unreachable");
  }
}
