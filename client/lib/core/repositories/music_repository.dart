import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../../api_client.dart';
import '../../database/database.dart'
    hide
        MusicTrack,
        ListeningEvent,
        Playlist,
        PlaylistTrack,
        DownloadQueueItem;
import '../../database/music_dao.dart';
import '../offline_music_download.dart';
import '../telemetry/telemetry_reporter.dart';
import 'base_daemon_repository.dart';
import 'models/music_models.dart';

/// Music library (tracks from `GET /api/v1/music/tracks`).
class MusicRepository extends DaemonRepository {
  static final MusicRepository instance = MusicRepository._();

  MusicRepository._();

  final ValueNotifier<List<MusicTrack>> tracks = ValueNotifier(const []);

  /// Device-local offline tracks (Drift vault + app documents dir).
  final ValueNotifier<List<OfflineMusicTrack>> offlineTracks =
      ValueNotifier(const []);

  @override
  Future<void> load() async {
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
  Future<void> refresh() => load();

  /// Load device-local offline tracks from the local Drift vault.
  Future<void> loadOffline() async {
    try {
      final dao = MusicDao(AppDatabase.instance);
      final rows = await dao.getOfflineTracks();
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
      final dao = MusicDao(AppDatabase.instance);
      await dao.insertOfflineTrack(
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
      final dao = MusicDao(AppDatabase.instance);
      final row = await dao.getOfflineTrack(trackId);
      if (row != null) {
        await deleteDownloadedFile(row.filePath);
      }
      await dao.deleteOfflineTrack(trackId);
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

  // --- Liked Songs ---
  Future<List<MusicTrack>> getLikedTracks() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/music/liked');
      if (res is List) {
        return res
            .whereType<Map>()
            .map((m) => MusicTrack.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (e) {
      debugPrint('Get liked tracks error: $e');
    }
    return const [];
  }

  Future<bool> toggleLike(MusicTrack track) async {
    try {
      await ApiClient.instance.postDaemon('/api/v1/music/liked', {'track_id': track.id});
      return true;
    } catch (e) {
      debugPrint('Toggle like error: $e');
      return false;
    }
  }

  // --- Playlists ---
  Future<List<Playlist>> getPlaylists({bool? smart}) async {
    try {
      String url = '/api/v1/music/playlists';
      if (smart != null) {
        url += '?smart=${smart ? "true" : "false"}';
      }
      final res = await ApiClient.instance.getDaemon(url);
      if (res is List) {
        return res
            .whereType<Map>()
            .map((m) => Playlist.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (e) {
      debugPrint('Get playlists error: $e');
    }
    return const [];
  }

  Future<Playlist?> createPlaylist(PlaylistCreate create) async {
    try {
      final res = await ApiClient.instance.postDaemon('/api/v1/music/playlists', create.toJson());
      if (res is Map) {
        return Playlist.fromJson(Map<String, dynamic>.from(res));
      }
    } catch (e) {
      debugPrint('Create playlist error: $e');
    }
    return null;
  }

  Future<Playlist?> getPlaylist(String id) async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/music/playlists/$id');
      if (res is Map) {
        return Playlist.fromJson(Map<String, dynamic>.from(res));
      }
    } catch (e) {
      debugPrint('Get playlist error: $e');
    }
    return null;
  }

  Future<bool> updatePlaylist(String id, PlaylistUpdate update) async {
    try {
      await ApiClient.instance.patchDaemon('/api/v1/music/playlists/$id', update.toJson());
      return true;
    } catch (e) {
      debugPrint('Update playlist error: $e');
      return false;
    }
  }

  Future<bool> deletePlaylist(String id) async {
    try {
      await ApiClient.instance.deleteDaemon('/api/v1/music/playlists/$id');
      return true;
    } catch (e) {
      debugPrint('Delete playlist error: $e');
      return false;
    }
  }

  Future<List<PlaylistTrack>> getPlaylistTracks(String playlistId) async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/music/playlists/$playlistId/tracks');
      if (res is List) {
        return res
            .whereType<Map>()
            .map((m) => PlaylistTrack.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (e) {
      debugPrint('Get playlist tracks error: $e');
    }
    return const [];
  }

  Future<bool> addTrackToPlaylist(String playlistId, String trackId) async {
    try {
      await ApiClient.instance.postDaemon('/api/v1/music/playlists/$playlistId/tracks', {'track_id': trackId});
      return true;
    } catch (e) {
      debugPrint('Add track to playlist error: $e');
      return false;
    }
  }

  Future<bool> removeTrackFromPlaylist(String playlistId, String trackId) async {
    try {
      await ApiClient.instance.deleteDaemon('/api/v1/music/playlists/$playlistId/tracks/$trackId');
      return true;
    } catch (e) {
      debugPrint('Remove track from playlist error: $e');
      return false;
    }
  }

  Future<bool> reorderPlaylistTrack(String playlistId, String trackId, int newPosition) async {
    try {
      await ApiClient.instance.patchDaemon('/api/v1/music/playlists/$playlistId/tracks/reorder', {
        'track_id': trackId,
        'new_position': newPosition,
      });
      return true;
    } catch (e) {
      debugPrint('Reorder playlist track error: $e');
      return false;
    }
  }

  // --- Download Queue ---
  Future<List<DownloadQueueItem>> getDownloadQueue() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/music/downloads');
      if (res is List) {
        return res
            .whereType<Map>()
            .map((m) => DownloadQueueItem.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (e) {
      debugPrint('Get download queue error: $e');
    }
    return const [];
  }

  Future<bool> enqueueDownload(DownloadQueueCreate create) async {
    try {
      await ApiClient.instance.postDaemon('/api/v1/music/downloads', create.toJson());
      return true;
    } catch (e) {
      debugPrint('Enqueue download error: $e');
      return false;
    }
  }

  Future<bool> cancelDownload(String id) async {
    try {
      await ApiClient.instance.deleteDaemon('/api/v1/music/downloads/$id');
      return true;
    } catch (e) {
      debugPrint('Cancel download error: $e');
      return false;
    }
  }

  Future<bool> clearCompletedDownloads() async {
    try {
      await ApiClient.instance.deleteDaemon('/api/v1/music/downloads');
      return true;
    } catch (e) {
      debugPrint('Clear completed downloads error: $e');
      return false;
    }
  }

  // --- Listening History ---
  Future<bool> recordListening(ListeningEvent event) async {
    try {
      await ApiClient.instance.postDaemon('/api/v1/music/history', event.toJson());
      return true;
    } catch (e) {
      debugPrint('Record listening error: $e');
      return false;
    }
  }

  Future<List<ListeningEvent>> getListeningHistory({int limit = 200}) async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/music/history?limit=$limit');
      if (res is List) {
        return res
            .whereType<Map>()
            .map((m) => ListeningEvent.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (e) {
      debugPrint('Get listening history error: $e');
    }
    return const [];
  }

  Future<MusicStats> getMusicStats({int days = 30}) async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/music/stats?days=$days');
      if (res is Map) {
        return MusicStats.fromJson(Map<String, dynamic>.from(res));
      }
    } catch (e) {
      debugPrint('Get music stats error: $e');
    }
    return MusicStats.empty();
  }

  // --- Smart Playlists ---
  Future<List<MusicTrack>> getDiscoveryWeekly({int limit = 30}) async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/music/smart/discovery-weekly?limit=$limit');
      if (res is List) {
        return res
            .whereType<Map>()
            .map((m) => MusicTrack.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (e) {
      debugPrint('Get discovery weekly error: $e');
    }
    return const [];
  }

  Future<List<MusicTrack>> getDailyMix({required String seed, int limit = 50}) async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/music/smart/daily-mix?seed=${Uri.encodeComponent(seed)}&limit=$limit');
      if (res is List) {
        return res
            .whereType<Map>()
            .map((m) => MusicTrack.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (e) {
      debugPrint('Get daily mix error: $e');
    }
    return const [];
  }

  Future<List<MusicTrack>> getReleaseRadar({int limit = 30, int days = 14}) async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/music/smart/release-radar?limit=$limit&days=$days');
      if (res is List) {
        return res
            .whereType<Map>()
            .map((m) => MusicTrack.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (e) {
      debugPrint('Get release radar error: $e');
    }
    return const [];
  }

  Future<List<MusicTrack>> getRecommendations({int limit = 50}) async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/music/smart/recommendations?limit=$limit');
      if (res is List) {
        return res
            .whereType<Map>()
            .map((m) => MusicTrack.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (e) {
      debugPrint('Get recommendations error: $e');
    }
    return const [];
  }
}
