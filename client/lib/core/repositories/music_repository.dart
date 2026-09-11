import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
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
import '../services/local_audio_metadata_service.dart';
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
      loadOffline(),
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
      for (final r in rows) {
        final track = MusicTrack(
          id: r.id,
          title: r.title,
          artist: r.artist ?? '',
          album: r.album ?? '',
          thumbnail: r.thumbnail ?? '',
          thumbnailUrl: r.thumbnail ?? '',
          filePath: r.filePath,
          duration: r.duration.toDouble(),
        );
        rememberTrack(track);
        await dao.upsertTrack(
          MusicTracksCompanion.insert(
            id: r.id,
            title: r.title,
            artist: Value(r.artist),
            album: Value(r.album),
            thumbnailUrl: Value(r.thumbnail),
            filePath: r.filePath,
            duration: Value(r.duration.toInt()),
            addedAt: r.downloadedAt,
            updatedAt: r.downloadedAt,
          ),
        );
      }
    } catch (e) {
      debugPrint('Load offline music error: $e');
    }
  }

  /// Imports a list of local audio files, parses ID3/FLAC/M4A metadata & covers,
  /// and saves them to the local Drift database.
  Future<int> importLocalAudioFiles(
    List<String> filePaths, {
    void Function(int current, int total, String name)? onProgress,
  }) async {
    if (filePaths.isEmpty) return 0;
    int imported = 0;
    final dao = MusicDao(AppDatabase.instance);

    for (int i = 0; i < filePaths.length; i++) {
      final path = filePaths[i];
      try {
        final file = File(path);
        if (!await file.exists()) continue;

        onProgress?.call(i + 1, filePaths.length, file.uri.pathSegments.last);

        final meta = await LocalAudioMetadataService.instance.readMetadata(file);
        final id = 'local_${md5.convert(utf8.encode(path)).toString()}';

        await dao.insertOfflineTrack(
          OfflineMusicTracksCompanion.insert(
            id: id,
            title: meta.title,
            artist: Value(meta.artist),
            album: Value(meta.album),
            thumbnail: Value(meta.thumbnailPath),
            filePath: path,
            duration: Value(meta.duration),
            downloadedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        await dao.upsertTrack(
          MusicTracksCompanion.insert(
            id: id,
            title: meta.title,
            artist: Value(meta.artist),
            album: Value(meta.album),
            thumbnailUrl: Value(meta.thumbnailPath),
            filePath: path,
            duration: Value(meta.duration.toInt()),
            addedAt: DateTime.now().millisecondsSinceEpoch,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        rememberTrack(MusicTrack(
          id: id,
          title: meta.title,
          artist: meta.artist,
          album: meta.album,
          thumbnail: meta.thumbnailPath ?? '',
          duration: meta.duration,
          filePath: path,
        ));
        imported++;
      } catch (e) {
        debugPrint('Error importing local audio file $path: $e');
      }
    }

    await loadOffline();
    return imported;
  }

  /// Recursively scans a local directory for audio files and imports them.
  Future<int> scanLocalDirectory(
    String dirPath, {
    void Function(int current, int total, String name)? onProgress,
  }) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) return 0;

      final supportedExts =
          LocalAudioMetadataService.supportedAudioExtensions.toSet();
      final audioPaths = <String>[];

      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final ext = entity.path.toLowerCase().split('.').last;
          if (supportedExts.contains('.$ext')) {
            audioPaths.add(entity.path);
          }
        }
      }

      return await importLocalAudioFiles(audioPaths, onProgress: onProgress);
    } catch (e) {
      debugPrint('Error scanning local directory $dirPath: $e');
      return 0;
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
  Future<void> download(MusicTrack track, {String qualityMode = 'best'}) async {
    rememberTrack(track);
    try {
      await ApiClient.instance.postDaemon('/api/v1/music/download', {
        'video_id': track.id,
        'thumbnail': track.thumbnail,
        'quality_mode': qualityMode,
      });
      TelemetryReporter.instance.track('music', 'download_started', {
        'track_id': track.id,
        'quality_mode': qualityMode,
      });
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
      final dao = MusicDao(AppDatabase.instance);
      await dao.upsertTrack(
        MusicTracksCompanion.insert(
          id: track.id,
          title: track.title,
          artist: Value(track.artist),
          album: Value(track.album),
          thumbnailUrl: Value(track.thumbnail.isNotEmpty ? track.thumbnail : track.thumbnailUrl),
          filePath: track.filePath,
          duration: Value(track.duration.toInt()),
          addedAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      if (wasLiked) {
        await dao.unlikeSong(track.id);
        await ApiClient.instance
            .deleteDaemon('/api/v1/music/liked/${track.id}');
      } else {
        await dao.likeSong(LikedSongsCompanion.insert(
          id: track.id,
          likedAt: DateTime.now().millisecondsSinceEpoch,
        ));
        await ApiClient.instance.postDaemon('/api/v1/music/liked', {
          'track_id': track.id,
          'title': track.title,
          'artist': track.artist,
          'album': track.album,
          'thumbnail': track.thumbnail.isNotEmpty ? track.thumbnail : track.thumbnailUrl,
          'file_path': track.filePath,
          'duration': track.duration,
        });
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
        final list = res
            .whereType<Map>()
            .map((m) => Playlist.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        playlists.value = list;
        try {
          final dao = MusicDao(AppDatabase.instance);
          for (final p in list) {
            await dao.insertPlaylist(PlaylistsCompanion.insert(
              id: p.id,
              name: p.name,
              description: Value(p.description),
              coverArtUrl: Value(p.coverArtUrl),
              isSmart: Value(p.isSmart),
              smartType: Value(p.smartType),
              smartConfig: Value(p.smartConfig),
              trackCount: Value(p.trackCount),
              totalDuration: Value(p.totalDuration),
              createdAt: p.createdAt,
              updatedAt: p.updatedAt,
            ));
          }
        } catch (_) {}
        return;
      }
    } catch (e) {
      debugPrint('Load playlists error: $e');
    }
    // Fallback to local Drift DB
    try {
      final dao = MusicDao(AppDatabase.instance);
      final localPls = await dao.watchPlaylists().first;
      playlists.value = localPls
          .map((p) => Playlist(
                id: p.id,
                name: p.name,
                description: p.description ?? '',
                coverArtUrl: p.coverArtUrl ?? '',
                isSmart: p.isSmart,
                smartType: p.smartType ?? '',
                smartConfig: p.smartConfig ?? '',
                trackCount: p.trackCount,
                totalDuration: p.totalDuration,
                createdAt: p.createdAt,
                updatedAt: p.updatedAt,
              ))
          .toList();
    } catch (e) {
      debugPrint('Load offline playlists error: $e');
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
    Playlist? pl;
    try {
      final res = await ApiClient.instance.postDaemon('/api/v1/music/playlists', create.toJson());
      if (res is Map) {
        final map = Map<String, dynamic>.from(res);
        final id = map['id']?.toString() ?? '';
        pl = Playlist(
          id: id,
          name: create.name,
          description: create.description,
          isSmart: create.isSmart,
          smartType: create.smartType,
          smartConfig: create.smartConfig,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
      }
    } catch (e) {
      debugPrint('Create playlist error: $e');
    }

    try {
      final dao = MusicDao(AppDatabase.instance);
      final now = DateTime.now().millisecondsSinceEpoch;
      final plId = pl?.id ?? 'pl_local_${md5.convert(utf8.encode("${create.name}_$now")).toString().substring(0, 12)}';
      await dao.insertPlaylist(PlaylistsCompanion.insert(
        id: plId,
        name: create.name,
        description: Value(create.description),
        isSmart: Value(create.isSmart),
        smartType: Value(create.smartType),
        smartConfig: Value(create.smartConfig),
        trackCount: Value(pl?.trackCount ?? 0),
        totalDuration: Value(pl?.totalDuration ?? 0),
        createdAt: pl?.createdAt ?? now,
        updatedAt: pl?.updatedAt ?? now,
      ));
      pl ??= Playlist(
        id: plId,
        name: create.name,
        description: create.description,
        isSmart: create.isSmart,
        smartType: create.smartType,
        smartConfig: create.smartConfig,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      debugPrint('Insert local playlist error: $e');
    }

    await loadPlaylists();
    return pl;
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
    } catch (e) {
      debugPrint('Delete playlist error: $e');
    }
    try {
      final dao = MusicDao(AppDatabase.instance);
      await dao.deletePlaylist(id);
    } catch (e) {
      debugPrint('Delete local playlist error: $e');
    }
    await loadPlaylists();
    return true;
  }

  Future<List<PlaylistTrack>> getPlaylistTracks(String playlistId) async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/music/playlists/$playlistId/tracks');
      if (res is List) {
        final list = res
            .whereType<Map>()
            .map((m) => PlaylistTrack.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        for (final pt in list) {
          rememberTrack(pt.track);
        }
        return list;
      }
    } catch (e) {
      debugPrint('Get playlist tracks error: $e');
    }
    // Fallback to local Drift DB
    try {
      final dao = MusicDao(AppDatabase.instance);
      final localTracks = await dao.getPlaylistTracksWithDetails(playlistId);
      if (localTracks.isNotEmpty) {
        return localTracks.asMap().entries.map((e) {
          final t = MusicTrack(
            id: e.value.id,
            title: e.value.title,
            artist: e.value.artist ?? 'Unknown',
            album: e.value.album ?? '',
            thumbnail: e.value.thumbnailUrl ?? '',
            thumbnailUrl: e.value.thumbnailUrl ?? '',
            filePath: e.value.filePath,
            duration: e.value.duration.toDouble(),
          );
          rememberTrack(t);
          return PlaylistTrack(track: t, position: e.key);
        }).toList();
      }
    } catch (e) {
      debugPrint('Local playlist fallback error: $e');
    }
    return const [];
  }

  Future<bool> addTrackToPlaylist(String playlistId, String trackId, {MusicTrack? track}) async {
    try {
      final t = track ?? getTrackMetadata(trackId);
      final dao = MusicDao(AppDatabase.instance);
      if (t != null) {
        await dao.upsertTrack(
          MusicTracksCompanion.insert(
            id: t.id,
            title: t.title,
            artist: Value(t.artist),
            album: Value(t.album),
            thumbnailUrl: Value(t.thumbnail.isNotEmpty ? t.thumbnail : t.thumbnailUrl),
            filePath: t.filePath,
            duration: Value(t.duration.toInt()),
            addedAt: DateTime.now().millisecondsSinceEpoch,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }
      await dao.addTrackToPlaylist(playlistId, trackId);
      await dao.updatePlaylistStats(playlistId);

      final body = <String, dynamic>{'track_id': trackId};
      if (t != null) {
        body['title'] = t.title;
        body['artist'] = t.artist;
        body['album'] = t.album;
        body['thumbnail'] = t.thumbnail.isNotEmpty ? t.thumbnail : t.thumbnailUrl;
        body['file_path'] = t.filePath;
        body['duration'] = t.duration;
      }
      await ApiClient.instance.postDaemon('/api/v1/music/playlists/$playlistId/tracks', body);
      return true;
    } catch (e) {
      debugPrint('Add track to playlist error: $e');
      return false;
    }
  }

  Future<bool> removeTrackFromPlaylist(String playlistId, String trackId) async {
    try {
      final dao = MusicDao(AppDatabase.instance);
      await dao.removeTrackFromPlaylist(playlistId, trackId);
      await dao.updatePlaylistStats(playlistId);
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
  Future<bool> recordListening(ListeningEvent event, {String? artist, String? genre}) async {
    try {
      final jsonMap = event.toJson();
      if (artist != null && artist.isNotEmpty) jsonMap['artist'] = artist;
      if (genre != null && genre.isNotEmpty) jsonMap['genre'] = genre;
      await ApiClient.instance.postDaemon('/api/v1/music/history', jsonMap);
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

  Future<List<MusicTrack>> getRecommendations({
    String? seedTrackId,
    String? artist,
    String? genre,
    int limit = 20,
    String? mode,
  }) async {
    try {
      var endpoint = '/api/v1/music/recommendations?limit=$limit';
      if (seedTrackId != null && seedTrackId.isNotEmpty) {
        endpoint += '&id=${Uri.encodeComponent(seedTrackId)}';
      }
      if (artist != null && artist.isNotEmpty) {
        endpoint += '&artist=${Uri.encodeComponent(artist)}';
      }
      if (genre != null && genre.isNotEmpty) {
        endpoint += '&genre=${Uri.encodeComponent(genre)}';
      }
      if (mode != null && mode.isNotEmpty) {
        endpoint += '&mode=${Uri.encodeComponent(mode)}';
      }
      final res = await ApiClient.instance.getDaemon(endpoint);
      if (res is List && res.isNotEmpty) {
        final list = res
            .whereType<Map>()
            .map((m) => MusicTrack.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        rememberTracks(list);
        return list;
      }
    } catch (e) {
      debugPrint('Get recommendations error: $e');
    }

    // Local / Offline Radio fallback via Drift database
    try {
      final dao = MusicDao(AppDatabase.instance);
      final localRadio = await dao.getLocalTrackRadio(
        seedTrackId: seedTrackId ?? '',
        artist: artist,
        genre: genre,
        limit: limit,
      );
      if (localRadio.isNotEmpty) {
        final mapped = localRadio
            .map((r) => MusicTrack(
                  id: r.id,
                  title: r.title,
                  artist: r.artist ?? '',
                  album: r.album ?? '',
                  thumbnail: r.thumbnailUrl ?? '',
                  thumbnailUrl: r.thumbnailUrl ?? '',
                  filePath: r.filePath,
                  duration: r.duration.toDouble(),
                  genre: r.genre ?? '',
                  year: r.year,
                ))
            .toList();
        rememberTracks(mapped);
        return mapped;
      }
    } catch (e) {
      debugPrint('Local track radio fallback error: $e');
    }

    return const [];
  }
}
