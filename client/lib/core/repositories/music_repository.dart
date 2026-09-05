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

  /// Reactive set of Liked track IDs and list of Liked tracks.
  final ValueNotifier<Set<String>> likedTrackIds = ValueNotifier({});
  final ValueNotifier<List<MusicTrack>> likedTracks = ValueNotifier(const []);

  /// Reactive list of user playlists.
  final ValueNotifier<List<Playlist>> playlists = ValueNotifier(const []);

  /// Reactive daemon download queue.
  final ValueNotifier<List<DownloadQueueItem>> downloadQueue =
      ValueNotifier(const []);

  /// Known track metadata cache for resolving titles/artists/thumbnails in queue & UI.
  final Map<String, MusicTrack> knownTrackMetadata = {};

  void rememberTrack(MusicTrack track) {
    if (track.id.isNotEmpty) {
      knownTrackMetadata[track.id] = track;
    }
  }

  void rememberTracks(Iterable<MusicTrack> newTracks) {
    for (final t in newTracks) {
      if (t.id.isNotEmpty) knownTrackMetadata[t.id] = t;
    }
  }

  MusicTrack? getTrackMetadata(String trackId) {
    if (knownTrackMetadata.containsKey(trackId)) return knownTrackMetadata[trackId];
    for (final t in tracks.value) {
      if (t.id == trackId) {
        knownTrackMetadata[trackId] = t;
        return t;
      }
    }
    return null;
  }

  @override
  Future<void> load() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/music/tracks');
      if (res is List) {
        final loaded = res
            .whereType<Map>()
            .map((m) => MusicTrack.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        tracks.value = loaded;
        rememberTracks(loaded);
      }
    } catch (_) {
      // daemon offline: keep last known list
    }
    await Future.wait([
      loadLiked(),
      loadPlaylists(),
      loadDownloadQueue(),
    ]);
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
        final list = res
            .whereType<Map>()
            .map((m) => MusicTrack.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        rememberTracks(list);
        return list;
      }
    } catch (e) {
      debugPrint('Music search error: $e');
    }
    return const [];
  }

  /// Download a search result to the daemon's library (artist folders).
  Future<void> download(MusicTrack track) async {
    rememberTrack(track);
    try {
      await ApiClient.instance.postDaemon('/api/v1/music/download', {
        'video_id': track.id,
        'thumbnail': track.thumbnail,
      });
      TelemetryReporter.instance.track('music', 'download_started', {'track_id': track.id});
      await loadDownloadQueue();
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

  bool isLiked(String trackId) => likedTrackIds.value.contains(trackId);

  // --- Liked Songs ---
  Future<void> loadLiked() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/music/liked');
      if (res is List) {
        final list = res
            .whereType<Map>()
            .map((m) => MusicTrack.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        likedTracks.value = list;
        likedTrackIds.value = list.map((t) => t.id).toSet();
      }
    } catch (e) {
      debugPrint('Load liked tracks error: $e');
    }
  }

  Future<List<MusicTrack>> getLikedTracks() async {
    await loadLiked();
    return likedTracks.value;
  }

  Future<bool> toggleLike(MusicTrack track) async {
    final currentIds = Set<String>.from(likedTrackIds.value);
    final wasLiked = currentIds.contains(track.id);

    // Optimistic state update
    if (wasLiked) {
      currentIds.remove(track.id);
      likedTracks.value =
          likedTracks.value.where((t) => t.id != track.id).toList();
    } else {
      currentIds.add(track.id);
      likedTracks.value = [track, ...likedTracks.value];
    }
    likedTrackIds.value = currentIds;

    try {
      if (wasLiked) {
        await ApiClient.instance
            .deleteDaemon('/api/v1/music/liked/${track.id}');
      } else {
        await ApiClient.instance
            .postDaemon('/api/v1/music/liked', {'track_id': track.id});
      }
      return true;
    } catch (e) {
      debugPrint('Toggle like error: $e');
      // Revert optimistic update on failure
      await loadLiked();
      return false;
    }
  }

  // --- Playlists ---
  Future<void> loadPlaylists() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/music/playlists');
      if (res is List) {
        playlists.value = res
            .whereType<Map>()
            .map((m) => Playlist.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (e) {
      debugPrint('Load playlists error: $e');
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
  Future<void> loadDownloadQueue() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/music/downloads');
      if (res is List) {
        downloadQueue.value = res
            .whereType<Map>()
            .map((m) {
              final item = DownloadQueueItem.fromJson(Map<String, dynamic>.from(m));
              final meta = getTrackMetadata(item.trackId);
              if (meta != null && (item.customTitle == null || item.customTitle!.isEmpty)) {
                return DownloadQueueItem(
                  id: item.id,
                  trackId: item.trackId,
                  url: item.url,
                  destinationPath: item.destinationPath,
                  status: item.status,
                  priority: item.priority,
                  retryCount: item.retryCount,
                  totalBytes: item.totalBytes,
                  downloadedBytes: item.downloadedBytes,
                  errorMessage: item.errorMessage,
                  wifiOnly: item.wifiOnly,
                  chargingOnly: item.chargingOnly,
                  createdAt: item.createdAt,
                  startedAt: item.startedAt,
                  completedAt: item.completedAt,
                  customTitle: meta.title,
                  customArtist: meta.artist,
                  customThumbnail: meta.thumbnail,
                );
              }
              return item;
            })
            .toList();
      }
    } catch (e) {
      debugPrint('Load download queue error: $e');
    }
  }

  Future<List<DownloadQueueItem>> getDownloadQueue() async {
    await loadDownloadQueue();
    return downloadQueue.value;
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
