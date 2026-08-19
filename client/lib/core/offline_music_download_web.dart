import 'package:web/web.dart' as web;

/// Web browsers cannot persist files the app can read back, so we trigger a
/// native browser "Save as" download of the audio file instead.
/// Returns an empty path (no app-readable local file on web).
Future<String> downloadToDevice(
  String url,
  String trackId, {
  void Function(int received, int total)? onProgress,
}) async {
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = '$trackId.mp3'
    ..style.display = 'none';
  web.document.body?.appendChild(a);
  a.click();
  a.remove();
  return '';
}

Future<void> deleteDownloadedFile(String path) async {
  // No app-managed file on web.
}