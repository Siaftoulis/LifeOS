import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../api_client.dart';
import '../telemetry/telemetry_reporter.dart';
import 'base_daemon_repository.dart';
import 'models/youtube_models.dart';

/// Downloaded videos (`GET /api/v1/youtube/videos`).
class YoutubeRepository extends DaemonRepository {
  static final YoutubeRepository instance = YoutubeRepository._();

  YoutubeRepository._();

  final ValueNotifier<List<YoutubeVideo>> videos = ValueNotifier(const []);

  @override
  Future<void> load() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/youtube/videos');
      if (res is List) {
        videos.value = res
            .whereType<Map>()
            .map((m) => YoutubeVideo.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (_) {}
  }

  /// NewPipe search: `POST /api/v1/youtube/search`.
  Future<List<YoutubeVideo>> search(String query) async {
    try {
      final res = await ApiClient.instance
          .postDaemonSlow('/api/v1/youtube/search', {'query': query});
      if (res is List) {
        return res
            .whereType<Map>()
            .map((m) => YoutubeVideo.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  /// Resolved streams for a video: `GET /api/v1/youtube/streams`.
  Future<YoutubeStreamMeta> streams(String id) async {
    try {
      final res = await ApiClient.instance.getDaemonSlow('/api/v1/youtube/streams?id=$id');
      if (res is Map) {
        return YoutubeStreamMeta.fromJson(Map<String, dynamic>.from(res));
      }
    } catch (_) {}
    return YoutubeStreamMeta(id: id, live: false);
  }

  /// Download a video to the daemon library: `POST /api/v1/youtube/download`.
  Future<void> download(String id) async {
    try {
      await ApiClient.instance.postDaemon('/api/v1/youtube/download', {'id': id});
      TelemetryReporter.instance.track('youtube', 'download_started', {'video_id': id});
    } catch (_) {}
  }

  /// Start a watch session: `POST /api/v1/youtube/session/start`.
  Future<YoutubeSession> sessionStart() async {
    try {
      final res = await ApiClient.instance.postDaemon('/api/v1/youtube/session/start', {});
      if (res is Map) return YoutubeSession.fromJson(Map<String, dynamic>.from(res));
    } catch (_) {}
    return const YoutubeSession(active: false);
  }

  /// Current session state: `GET /api/v1/youtube/session`.
  Future<YoutubeSession> sessionStatus() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/youtube/session');
      if (res is Map) return YoutubeSession.fromJson(Map<String, dynamic>.from(res));
    } catch (_) {}
    return const YoutubeSession(active: false);
  }

  /// Stop the watch session and get the charge: `POST /api/v1/youtube/session/stop`.
  Future<SessionEnded> sessionStop() async {
    try {
      final res = await ApiClient.instance.postDaemon('/api/v1/youtube/session/stop', {});
      if (res is Map) return SessionEnded.fromJson(Map<String, dynamic>.from(res));
    } catch (_) {}
    return const SessionEnded(status: 'error');
  }
}
