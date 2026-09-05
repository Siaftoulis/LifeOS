import 'package:flutter/foundation.dart';

/// Sanitizes music thumbnail URLs, ensuring HTTPS on web when needed.
String sanitizeMusicThumbnailUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return '';
  if (kIsWeb && Uri.base.scheme == 'https' && trimmed.startsWith('http://')) {
    return trimmed.replaceFirst('http://', 'https://');
  }
  if (trimmed.startsWith('http://')) {
    return trimmed.replaceFirst('http://', 'https://');
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
