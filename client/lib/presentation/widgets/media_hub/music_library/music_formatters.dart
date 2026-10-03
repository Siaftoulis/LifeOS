
/// Sanitizes music thumbnail URLs and scales them to studio high definition (1000-1400px).
String sanitizeMusicThumbnailUrl(String url) {
  var trimmed = url.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('http://')) {
    trimmed = trimmed.replaceFirst('http://', 'https://');
  }

  // 1. iTunes high-definition upscaling (up to 1400x1400)
  if (trimmed.contains('mzstatic.com')) {
    trimmed = trimmed.replaceAll(RegExp(r'\d+x\d+bb\.jpg'), '1400x1400bb.jpg');
    trimmed = trimmed.replaceAll(RegExp(r'\d+x\d+bb\.png'), '1400x1400bb.png');
  }

  // 2. YouTube Music high-definition upscaling (up to 1200x1200)
  if (trimmed.contains('googleusercontent.com')) {
    trimmed = trimmed.replaceAll(RegExp(r'=w\d+-h\d+[^?]*'), '=w1200-h1200-l90-rj');
    trimmed = trimmed.replaceAll(RegExp(r'=s\d+[^?]*'), '=s1200-rj');
  }

  // 3. Deezer cover art upscaling (up to 1000x1000)
  if (trimmed.contains('dzcdn.net')) {
    trimmed = trimmed.replaceAll(RegExp(r'/\d+x\d+-\d+\.jpg'), '/1000x1000-000000-80-0-0.jpg');
    trimmed = trimmed.replaceAll(RegExp(r'/\d+x\d+\.jpg'), '/1000x1000.jpg');
  }

  return trimmed;
}

/// Formats duration in seconds into `m:ss` or `h:mm:ss`.
///
/// If [allowEmpty] is true and [seconds] <= 0, returns an empty string.
String formatTrackDuration(double seconds, {bool allowEmpty = false}) {
  if (seconds <= 0) {
    return allowEmpty ? '' : '0:00';
  }
  final s = seconds.round();
  final m = s ~/ 60;
  final remS = s % 60;
  if (m >= 60) {
    final h = m ~/ 60;
    final remM = m % 60;
    return '$h:${remM.toString().padLeft(2, '0')}:${remS.toString().padLeft(2, '0')}';
  }
  return '$m:${remS.toString().padLeft(2, '0')}';
}

/// Formats a [Duration] object into `m:ss` or `h:mm:ss`.
///
/// Negative durations return `'00:00'`.
String formatDurationSpan(Duration d) {
  if (d.isNegative) return '00:00';
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (d.inHours > 0) {
    return '${d.inHours}:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}
