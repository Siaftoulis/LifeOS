import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../api_client.dart';
import '../database/database.dart';
import 'offline_music_download.dart';
import 'telemetry/telemetry_reporter.dart';

class MusicTrack {
  const MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.duration = 0,
    this.thumbnail = '',
  });

  factory MusicTrack.fromJson(Map<String, dynamic> json) => MusicTrack(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Unknown',
        artist: json['artist']?.toString() ?? 'Unknown',
        album: json['album']?.toString() ?? '',
        duration: (json['duration'] as num?)?.toDouble() ?? 0,
        thumbnail: json['thumbnail']?.toString() ?? '',
      );

  final String id;
  final String title;
  final String artist;
  final String album;
  final double duration;
  final String thumbnail;
}

class YoutubeVideo {
  const YoutubeVideo({
    required this.id,
    required this.title,
    this.size = '',
    this.uploader = '',
    this.thumbnail = '',
    this.duration = 0,
    this.live = false,
  });

  factory YoutubeVideo.fromJson(Map<String, dynamic> json) => YoutubeVideo(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Untitled Video',
        size: json['size']?.toString() ?? '',
        uploader: json['uploader']?.toString() ?? '',
        thumbnail: json['thumbnail']?.toString() ?? '',
        duration: (json['duration'] as num?)?.toInt() ?? 0,
        live: json['live'] == true,
      );

  final String id;
  final String title;
  final String size;
  final String uploader;
  final String thumbnail;
  final int duration;
  final bool live;
}

class YoutubeStreamMeta {
  const YoutubeStreamMeta({
    required this.id,
    required this.live,
    this.title = '',
    this.hls = '',
    this.mp4 = '',
  });

  factory YoutubeStreamMeta.fromJson(Map<String, dynamic> json) => YoutubeStreamMeta(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        live: json['live'] == true,
        hls: json['hls']?.toString() ?? '',
        mp4: json['mp4']?.toString() ?? '',
      );

  final String id;
  final String title;
  final bool live;
  final String hls;
  final String mp4;
}

class YoutubeSession {
  const YoutubeSession({
    required this.active,
    this.startedAt = 0,
    this.elapsedMinutes = 0,
    this.estCost = 0,
  });

  factory YoutubeSession.fromJson(Map<String, dynamic> json) => YoutubeSession(
        active: json['active'] == true,
        startedAt: (json['started_at'] as num?)?.toInt() ?? 0,
        elapsedMinutes: (json['elapsed_minutes'] as num?)?.toInt() ?? 0,
        estCost: (json['est_cost'] as num?)?.toInt() ?? 0,
      );

  final bool active;
  final int startedAt;
  final int elapsedMinutes;
  final int estCost;

  DateTime? get started => startedAt > 0
      ? DateTime.fromMillisecondsSinceEpoch(startedAt * 1000)
      : null;
}

class SessionEnded {
  const SessionEnded({
    required this.status,
    this.elapsedMinutes = 0,
    this.pointsDeducted = 0,
    this.newBalance = 0,
  });

  factory SessionEnded.fromJson(Map<String, dynamic> json) => SessionEnded(
        status: json['status']?.toString() ?? '',
        elapsedMinutes: (json['elapsed_minutes'] as num?)?.toInt() ?? 0,
        pointsDeducted: (json['points_deducted'] as num?)?.toInt() ?? 0,
        newBalance: (json['new_balance'] as num?)?.toInt() ?? 0,
      );

  final String status;
  final int elapsedMinutes;
  final int pointsDeducted;
  final int newBalance;
}

/// Points balance (`GET /api/v1/points/balance`): points + stars.
class PointsBalance {
  const PointsBalance({required this.points, required this.stars});

  factory PointsBalance.fromJson(Map<String, dynamic> json) => PointsBalance(
        points: (json['points'] as num?)?.toInt() ?? 0,
        stars: (json['stars'] as num?)?.toInt() ?? 0,
      );

  final int points;
  final int stars;
}

class SmartDevice {
  const SmartDevice({
    required this.deviceId,
    required this.name,
    required this.type,
    required this.state,
  });

  factory SmartDevice.fromJson(Map<String, dynamic> json) => SmartDevice(
        deviceId: json['device_id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        state: json['state']?.toString() ?? 'OFF',
      );

  final String deviceId;
  final String name;
  final String type;
  final String state;
}

class FlashcardDeck {
  const FlashcardDeck({required this.id, required this.name, required this.newCards, required this.dueCards});

  factory FlashcardDeck.fromJson(Map<String, dynamic> json) => FlashcardDeck(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Unknown Deck',
        newCards: (json['new_cards'] as num?)?.toInt() ?? 0,
        dueCards: (json['due_cards'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String name;
  final int newCards;
  final int dueCards;
}

/// Polls a daemon `GET` endpoint every 10s into a notifier (MovieRepository pattern).
abstract class _DaemonRepo {
  _DaemonRepo() {
    _load();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _load());
  }

  Timer? _timer;

  Future<void> _load();

  void dispose() {
    _timer?.cancel();
  }
}

/// Music library (tracks from `GET /api/v1/music/tracks`).
class MusicRepository extends _DaemonRepo {
  static final MusicRepository instance = MusicRepository._();

  MusicRepository._();

  final ValueNotifier<List<MusicTrack>> tracks = ValueNotifier(const []);

  /// Device-local offline tracks (Drift vault + app documents dir).
  final ValueNotifier<List<OfflineMusicTrack>> offlineTracks =
      ValueNotifier(const []);

  @override
  Future<void> _load() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/music/tracks');
      if (res is List) {
        tracks.value = res
            .whereType<Map>()
            .map((m) => MusicTrack.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (_) {
      // daemon offline: keep last known list
    }
  }
  /// Reload the track library from the daemon.
  Future<void> refresh() => _load();

  /// Load device-local offline tracks from the local Drift vault.
  Future<void> loadOffline() async {
    try {
      final rows = await AppDatabase.instance.musicDao.getOfflineTracks();
      rows.sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
      offlineTracks.value = rows;
    } catch (e) {
      debugPrint('Load offline music error: $e');
    }
  }

  bool isOffline(String trackId) =>
      offlineTracks.value.any((t) => t.id == trackId);

  String? offlineFilePath(String trackId) {
    for (final t in offlineTracks.value) {
      if (t.id == trackId && t.filePath.isNotEmpty) return t.filePath;
    }
    return null;
  }

  /// Download a library track to THIS device for offline playback.
  /// On web this triggers a browser "Save as" download instead.
  Future<bool> downloadOffline(MusicTrack track) async {
    try {
      final url =
          '${ApiClient.instance.daemonUrl}/api/v1/music/stream/?id=${track.id}';
      final path = await downloadToDevice(url, track.id);
      await AppDatabase.instance.musicDao.insertOfflineTrack(
        OfflineMusicTracksCompanion.insert(
          id: track.id,
          title: track.title,
          artist: Value(track.artist),
          album: Value(track.album),
          thumbnail: Value(track.thumbnail),
          filePath: path,
          duration: Value(track.duration),
          downloadedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      await loadOffline();
      TelemetryReporter.instance
          .track('music', 'offline_downloaded', {'track_id': track.id});
      return true;
    } catch (e) {
      debugPrint('Offline music download error: $e');
      return false;
    }
  }

  /// Remove a device-local offline track (file + DB row).
  Future<bool> deleteOffline(String trackId) async {
    try {
      final row = await AppDatabase.instance.musicDao.getOfflineTrack(trackId);
      if (row != null) {
        await deleteDownloadedFile(row.filePath);
      }
      await AppDatabase.instance.musicDao.deleteOfflineTrack(trackId);
      await loadOffline();
      return true;
    } catch (e) {
      debugPrint('Offline music delete error: $e');
      return false;
    }
  }

  /// YouTube-Music-style search: `POST /api/v1/music/search` → daemon yt-dlp.
  Future<List<MusicTrack>> search(String query) async {
    try {
      final res = await ApiClient.instance
          .postDaemonSlow('/api/v1/music/search', {'query': query});
      if (res is List) {
        return res
            .whereType<Map>()
            .map((m) => MusicTrack.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (e) {
      debugPrint('Music search error: $e');
    }
    return const [];
  }

  /// Download a search result to the daemon's library (artist folders).
  Future<void> download(MusicTrack track) async {
    try {
      await ApiClient.instance.postDaemon('/api/v1/music/download', {
        'video_id': track.id,
        'thumbnail': track.thumbnail,
      });
      TelemetryReporter.instance.track('music', 'download_started', {'track_id': track.id});
    } catch (_) {}
  }

  /// Delete a track from the daemon library and disk.
  Future<bool> deleteTrack(String trackId) async {
    try {
      await ApiClient.instance.deleteDaemon('/api/v1/music/tracks/$trackId');
      tracks.value = tracks.value.where((t) => t.id != trackId).toList();
      TelemetryReporter.instance.track('music', 'track_deleted', {'track_id': trackId});
      return true;
    } catch (e) {
      debugPrint('Delete track error: $e');
      return false;
    }
  }
}

/// Downloaded videos (`GET /api/v1/youtube/videos`).
class YoutubeRepository extends _DaemonRepo {
  static final YoutubeRepository instance = YoutubeRepository._();

  YoutubeRepository._();

  final ValueNotifier<List<YoutubeVideo>> videos = ValueNotifier(const []);

  @override
  Future<void> _load() async {
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

/// Points balance (`GET /api/v1/points/balance`), polled every 10s.
class PointsRepository extends _DaemonRepo {
  static final PointsRepository instance = PointsRepository._();

  PointsRepository._();

  final ValueNotifier<PointsBalance> balance = ValueNotifier(const PointsBalance(points: 0, stars: 0));

  @override
  Future<void> _load() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/points/balance');
      if (res is Map) {
        balance.value = PointsBalance.fromJson(Map<String, dynamic>.from(res));
        await _mirrorLocal(balance.value.points);
      }
    } catch (_) {}
  }

  /// Server truth → local drift mirror (u-admin-1), so widgets that read the
  /// local stream (gating, star panels, voucher panel) follow the daemon.
  /// ponytail: silent fail — offline keeps the last known local value.
  Future<void> _mirrorLocal(int serverPoints) async {
    try {
      final db = AppDatabase.instance;
      final user = await db.pointsDao.getUserProfile('u-admin-1');
      if (user != null && user.currentPoints != serverPoints) {
        await db.pointsDao.updateUser(user.copyWith(
          currentPoints: serverPoints,
          updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          isDirty: 0,
        ));
      }
    } catch (_) {}
  }

  Future<void> refresh() async => _load();
}

/// Smart home devices (`GET /api/v1/home/devices`), toggled via POST.
class HomeRepository extends _DaemonRepo {
  static final HomeRepository instance = HomeRepository._();

  HomeRepository._();

  final ValueNotifier<List<SmartDevice>> devices = ValueNotifier(const []);

  @override
  Future<void> _load() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/home/devices');
      if (res is List) {
        devices.value = res
            .whereType<Map>()
            .map((m) => SmartDevice.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (_) {}
  }

  Future<void> toggle(String deviceId) async {
    try {
      await ApiClient.instance
          .postDaemon('/api/v1/home/devices/toggle', {'device_id': deviceId});
      await _load();
      TelemetryReporter.instance.track('home', 'device_toggled', {'device_id': deviceId});
    } catch (_) {}
  }
}

/// Flashcard decks (`GET /api/v1/flashcards/decks`), created via POST.
class FlashcardsRepository extends _DaemonRepo {
  static final FlashcardsRepository instance = FlashcardsRepository._();

  FlashcardsRepository._();

  final ValueNotifier<List<FlashcardDeck>> decks = ValueNotifier(const []);

  @override
  Future<void> _load() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/flashcards/decks');
      if (res is List) {
        decks.value = res
            .whereType<Map>()
            .map((m) => FlashcardDeck.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (_) {}
  }

  Future<void> createDeck(String name) async {
    try {
      await ApiClient.instance
          .postDaemon('/api/v1/flashcards/decks/create', {'name': name});
      await _load();
      TelemetryReporter.instance.track('flashcards', 'deck_created', {'name': name});
    } catch (_) {}
  }
}