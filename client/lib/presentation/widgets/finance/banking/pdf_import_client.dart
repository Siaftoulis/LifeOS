import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../api_client.dart';
import '../../../../auth_service.dart';

class PdfImportResult {
  final double amount;
  final String title;
  final String date;

  PdfImportResult({required this.amount, required this.title, required this.date});

  factory PdfImportResult.fromJson(Map<String, dynamic> json) {
    return PdfImportResult(
      amount: (json['amount'] as num? ?? 0).toDouble(),
      title: json['title']?.toString() ?? 'Receipt',
      date: json['date']?.toString() ?? '',
    );
  }
}

class PdfImportClient {
  /// Uploads a receipt PDF to the daemon; returns the parsed amount/date, or
  /// null when the backend couldn't extract an amount.
  static Future<PdfImportResult?> parseReceipt(Uint8List bytes, String filename) async {
    final uri = Uri.parse('${ApiClient.instance.daemonUrl}/api/v1/banking/parse-pdf');
    final req = http.MultipartRequest('POST', uri);
    final token = AuthService.instance.token;
    if (token != null && token.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $token';
    }
    req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    try {
      final res = await req.send().timeout(const Duration(seconds: 20));
      final body = await res.stream.bytesToString();
      if (res.statusCode == 200) {
        return PdfImportResult.fromJson(jsonDecode(body));
      }
      debugPrint('parse-pdf failed ${res.statusCode}: $body');
    } catch (e) {
      debugPrint('parse-pdf error: $e');
    }
    return null;
  }
}