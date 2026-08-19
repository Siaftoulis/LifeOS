import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Saves a music stream to the device's app documents dir.
/// Returns the absolute local file path of the saved audio file.
Future<String> downloadToDevice(
  String url,
  String trackId, {
  void Function(int received, int total)? onProgress,
}) async {
  final docDir = await getApplicationDocumentsDirectory();
  final musicDir = Directory('${docDir.path}${Platform.pathSeparator}music_offline');
  if (!await musicDir.exists()) {
    await musicDir.create(recursive: true);
  }

  final res = await http.Client().get(Uri.parse(url)).timeout(const Duration(minutes: 10));
  if (res.statusCode != 200) {
    throw Exception('Download failed with status ${res.statusCode}');
  }

  var ext = '.mp3';
  final contentType = res.headers['content-type'] ?? '';
  if (contentType.contains('m4a') || contentType.contains('mp4')) {
    ext = '.m4a';
  } else if (contentType.contains('ogg')) {
    ext = '.ogg';
  }

  final file = File('${musicDir.path}${Platform.pathSeparator}$trackId$ext');
  await file.writeAsBytes(res.bodyBytes, flush: true);

  if (onProgress != null) {
    onProgress(res.bodyBytes.length, res.bodyBytes.length);
  }
  debugPrint('Offline music saved: ${file.path} (${res.bodyBytes.length} bytes)');
  return file.path;
}

Future<void> deleteDownloadedFile(String path) async {
  if (path.isEmpty) return;
  try {
    final f = File(path);
    if (await f.exists()) {
      await f.delete();
    }
  } catch (e) {
    debugPrint('Offline music delete failed: $e');
  }
}