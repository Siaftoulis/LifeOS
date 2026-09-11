import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'music_dao.g.dart';

@DriftAccessor(tables: [MusicTracks, Playlists, PlaylistTracks, OfflineMusicTracks, LikedSongs, DownloadQueue, ListeningHistory])
class MusicDao extends DatabaseAccessor<AppDatabase> with _$MusicDaoMixin {
  MusicDao(AppDatabase db) : super(db);

  // --- Tracks ---
  Stream<List<MusicTrack>> watchAllTracks() => select(musicTracks).watch();
  Future<List<MusicTrack>> getAllTracks() => select(musicTracks).get();
  Future<MusicTrack?> getTrack(String id) =>
      (select(musicTracks)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<int> insertTrack(MusicTracksCompanion entry) => into(musicTracks).insert(entry);
  Future<int> upsertTrack(MusicTracksCompanion entry) => into(musicTracks).insertOnConflictUpdate(entry);
  Future<bool> updateTrack(MusicTracksCompanion entry) => update(musicTracks).replace(entry);
  Future<int> deleteTrack(String id) =>
      (delete(musicTracks)..where((t) => t.id.equals(id))).go();
  Future<int> incrementPlayCount(String id) => customUpdate(
      'UPDATE music_tracks SET play_count = play_count + 1, last_played_at = ? WHERE id = ?',
      variables: [Variable.withInt(DateTime.now().millisecondsSinceEpoch), Variable.withString(id)]);

  // --- Liked Songs ---
  Stream<List<LikedSong>> watchLikedSongs() => select(likedSongs).watch();
  Future<List<LikedSong>> getLikedSongs() => select(likedSongs).get();
  Future<bool> isLiked(String trackId) async =>
      (await (select(likedSongs)..where((t) => t.id.equals(trackId))).getSingleOrNull()) != null;
  Future<int> likeSong(LikedSongsCompanion entry) => into(likedSongs).insert(entry);
  Future<int> unlikeSong(String trackId) =>
      (delete(likedSongs)..where((t) => t.id.equals(trackId))).go();
  Future<int> toggleLike(String trackId) async {
    final existing = await isLiked(trackId);
    if (existing) {
      return await unlikeSong(trackId);
    } else {
      return await likeSong(LikedSongsCompanion.insert(id: trackId, likedAt: DateTime.now().millisecondsSinceEpoch));
    }
  }
  Stream<List<MusicTrack>> watchLikedTracks() {
    return (select(musicTracks).join([
      innerJoin(likedSongs, likedSongs.id.equalsExp(musicTracks.id)),
    ])
          ..orderBy([OrderingTerm.desc(musicTracks.addedAt)]))
        .watch()
        .map((results) => results.map((r) => r.readTable(musicTracks)).toList());
  }

  // --- Playlists ---
  Stream<List<Playlist>> watchPlaylists() => (select(playlists)..orderBy([(p) => OrderingTerm.desc(p.updatedAt)])).watch();
  Stream<List<Playlist>> watchUserPlaylists() =>
      (select(playlists)..where((p) => p.isSmart.equals(false))..orderBy([(p) => OrderingTerm.desc(p.updatedAt)])).watch();
  Stream<List<Playlist>> watchSmartPlaylists() =>
      (select(playlists)..where((p) => p.isSmart.equals(true))).watch();
  Future<Playlist?> getPlaylist(String id) =>
      (select(playlists)..where((p) => p.id.equals(id))).getSingleOrNull();
  Future<int> insertPlaylist(PlaylistsCompanion entry) => into(playlists).insertOnConflictUpdate(entry);
  Future<bool> updatePlaylist(PlaylistsCompanion entry) => update(playlists).replace(entry);
  Future<int> deletePlaylist(String id) =>
      (delete(playlists)..where((p) => p.id.equals(id))).go();
  Future<int> updatePlaylistStats(String playlistId) async {
    final stats = await customSelect('''
      SELECT COUNT(*) as cnt, COALESCE(SUM(mt.duration), 0) as dur
      FROM playlist_tracks pt
      JOIN music_tracks mt ON mt.id = pt.track_id
      WHERE pt.playlist_id = ?
    ''', variables: [Variable.withString(playlistId)]).getSingle();
    return into(playlists).insertOnConflictUpdate(PlaylistsCompanion(
      id: Value(playlistId),
      trackCount: Value(stats.read<int>('cnt')),
      totalDuration: Value(stats.read<int>('dur')),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      isDirty: const Value(0),
    ));
  }

  // --- Playlist Tracks ---
  Stream<List<PlaylistTrack>> watchPlaylistTracks(String playlistId) =>
      (select(playlistTracks)..where((pt) => pt.playlistId.equals(playlistId))..orderBy([(pt) => OrderingTerm.asc(pt.position)])).watch();
  Future<List<PlaylistTrack>> getPlaylistTracks(String playlistId) =>
      (select(playlistTracks)..where((pt) => pt.playlistId.equals(playlistId))..orderBy([(pt) => OrderingTerm.asc(pt.position)])).get();
  Future<List<MusicTrack>> getPlaylistTracksWithDetails(String playlistId) async {
    final pl = await getPlaylist(playlistId);
    if (pl != null && pl.isSmart) {
      return getSmartPlaylistTracks(pl.smartType ?? '', pl.smartConfig ?? '');
    }
    return customSelect('''
      SELECT mt.* FROM music_tracks mt
      JOIN playlist_tracks pt ON pt.track_id = mt.id
      WHERE pt.playlist_id = ?
      ORDER BY pt.position ASC
    ''', variables: [Variable.withString(playlistId)], readsFrom: {musicTracks}).map((row) => _trackFromRow(row.data)).get();
  }

  Future<List<MusicTrack>> getSmartPlaylistTracks(String smartType, String smartConfig) async {
    final type = smartType.toLowerCase().trim();
    final cfg = smartConfig.toLowerCase().trim();
    switch (type) {
      case 'genre':
        return (select(musicTracks)
              ..where((t) => t.genre.lower().like('%$cfg%'))
              ..orderBy([(t) => OrderingTerm.asc(t.artist), (t) => OrderingTerm.asc(t.album)]))
            .get();
      case 'decade':
        final range = _parseDecadeRange(cfg);
        return (select(musicTracks)
              ..where((t) => t.year.isBiggerOrEqualValue(range.$1) & t.year.isSmallerOrEqualValue(range.$2))
              ..orderBy([(t) => OrderingTerm.desc(t.year), (t) => OrderingTerm.asc(t.artist)]))
            .get();
      case 'year':
        final y = int.tryParse(cfg) ?? 0;
        return (select(musicTracks)
              ..where((t) => t.year.equals(y))
              ..orderBy([(t) => OrderingTerm.asc(t.artist), (t) => OrderingTerm.asc(t.title)]))
            .get();
      case 'folder':
        final cleanFolder = cfg.replaceAll('/', '\\');
        return (select(musicTracks)
              ..where((t) => t.filePath.lower().like('%$cleanFolder%') | t.filePath.lower().like('%$cfg%'))
              ..orderBy([(t) => OrderingTerm.asc(t.filePath)]))
            .get();
      case 'recently_added':
        return (select(musicTracks)
              ..orderBy([(t) => OrderingTerm.desc(t.addedAt)])
              ..limit(100))
            .get();
      case 'most_played':
        return (select(musicTracks)
              ..where((t) => t.playCount.isBiggerThanValue(0))
              ..orderBy([(t) => OrderingTerm.desc(t.playCount)])
              ..limit(100))
            .get();
      default:
        if (cfg.isNotEmpty) {
          final q = '%$cfg%';
          return (select(musicTracks)
                ..where((t) => t.genre.lower().like(q) | t.filePath.lower().like(q) | t.title.lower().like(q))
                ..orderBy([(t) => OrderingTerm.asc(t.artist)]))
              .get();
        }
        return (select(musicTracks)..limit(100)).get();
    }
  }

  static (int, int) _parseDecadeRange(String input) {
    final s = input.toLowerCase().trim();
    if (s.contains('60')) return (1960, 1969);
    if (s.contains('70')) return (1970, 1979);
    if (s.contains('80')) return (1980, 1989);
    if (s.contains('90')) return (1990, 1999);
    if (s.contains('2000') || s == '00s') return (2000, 2009);
    if (s.contains('2010') || s == '10s') return (2010, 2019);
    if (s.contains('2020') || s == '20s') return (2020, 2029);
    final parts = s.split(RegExp(r'[-–]'));
    if (parts.length == 2) {
      final a = int.tryParse(parts[0].trim()) ?? 1900;
      final b = int.tryParse(parts[1].trim()) ?? 2099;
      return (a, b);
    }
    final y = int.tryParse(s) ?? 1980;
    return (y, y + 9);
  }
  Future<int> addTrackToPlaylist(String playlistId, String trackId, {int? position}) async {
    final maxPos = await customSelect('SELECT COALESCE(MAX(position), -1) + 1 as pos FROM playlist_tracks WHERE playlist_id = ?',
        variables: [Variable.withString(playlistId)]).getSingle();
    final pos = position ?? maxPos.read<int>('pos');
    return into(playlistTracks).insert(PlaylistTracksCompanion.insert(
      id: '$playlistId-$trackId',
      playlistId: playlistId,
      trackId: trackId,
      position: pos,
      addedAt: DateTime.now().millisecondsSinceEpoch,
    ));
  }
  Future<int> removeTrackFromPlaylist(String playlistId, String trackId) =>
      (delete(playlistTracks)..where((pt) => pt.playlistId.equals(playlistId) & pt.trackId.equals(trackId))).go();
  Future<int> reorderPlaylistTrack(String playlistId, String trackId, int newPosition) async {
    await transaction(() async {
      final current = await (select(playlistTracks)
          ..where((pt) => pt.playlistId.equals(playlistId) & pt.trackId.equals(trackId)))
        .getSingleOrNull();
      if (current == null) return;
      final oldPos = current.position;
      if (oldPos == newPosition) return;

      if (oldPos < newPosition) {
        // Moving down: shift items up
        await customUpdate(
          'UPDATE playlist_tracks SET position = position - 1 WHERE playlist_id = ? AND position > ? AND position <= ?',
          variables: [Variable.withString(playlistId), Variable.withInt(oldPos), Variable.withInt(newPosition)],
        );
      } else {
        // Moving up: shift items down
        await customUpdate(
          'UPDATE playlist_tracks SET position = position + 1 WHERE playlist_id = ? AND position >= ? AND position < ?',
          variables: [Variable.withString(playlistId), Variable.withInt(newPosition), Variable.withInt(oldPos)],
        );
      }
      await (update(playlistTracks)
            ..where((pt) => pt.playlistId.equals(playlistId) & pt.trackId.equals(trackId)))
          .write(PlaylistTracksCompanion(position: Value(newPosition)));
    });
    return await updatePlaylistStats(playlistId);
  }

  // --- Offline Tracks ---
  Stream<List<OfflineMusicTrack>> watchOfflineTracks() => select(offlineMusicTracks).watch();
  Future<List<OfflineMusicTrack>> getOfflineTracks() => select(offlineMusicTracks).get();
  Future<OfflineMusicTrack?> getOfflineTrack(String id) =>
      (select(offlineMusicTracks)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<int> insertOfflineTrack(OfflineMusicTracksCompanion entry) =>
      into(offlineMusicTracks).insertOnConflictUpdate(entry);
  Future<int> deleteOfflineTrack(String id) =>
      (delete(offlineMusicTracks)..where((t) => t.id.equals(id))).go();

  // --- Download Queue ---
  Stream<List<DownloadQueueItem>> watchDownloadQueue() =>
      (select(downloadQueue)..orderBy([(d) => OrderingTerm.desc(d.priority), (d) => OrderingTerm.asc(d.createdAt)])).watch();
  Stream<List<DownloadQueueItem>> watchActiveDownloads() =>
      (select(downloadQueue)..where((d) => d.status.isIn(['pending', 'downloading']))).watch();
  Future<List<DownloadQueueItem>> getDownloadQueue() => select(downloadQueue).get();
  Future<DownloadQueueItem?> getDownloadItem(String id) =>
      (select(downloadQueue)..where((d) => d.id.equals(id))).getSingleOrNull();
  Future<int> enqueueDownload(DownloadQueueCompanion entry) => into(downloadQueue).insert(entry);
  Future<int> updateDownloadStatus(String id, String status, {int? downloadedBytes, int? totalBytes, String? errorMessage}) async {
    return await (update(downloadQueue)..where((d) => d.id.equals(id))).write(DownloadQueueCompanion(
      status: Value(status),
      downloadedBytes: downloadedBytes != null ? Value(downloadedBytes) : const Value.absent(),
      totalBytes: totalBytes != null ? Value(totalBytes) : const Value.absent(),
      errorMessage: errorMessage != null ? Value(errorMessage) : const Value.absent(),
      startedAt: status == 'downloading' ? Value(DateTime.now().millisecondsSinceEpoch) : const Value.absent(),
      completedAt: status == 'completed' || status == 'failed' ? Value(DateTime.now().millisecondsSinceEpoch) : const Value.absent(),
    ));
  }
  Future<int> incrementDownloadRetry(String id) => customUpdate(
      'UPDATE download_queue SET retry_count = retry_count + 1 WHERE id = ?',
      variables: [Variable.withString(id)]);
  Future<int> cancelDownload(String id) =>
      (update(downloadQueue)..where((d) => d.id.equals(id))).write(DownloadQueueCompanion(status: Value('cancelled')));
  Future<int> clearCompletedDownloads() =>
      (delete(downloadQueue)..where((d) => d.status.equals('completed') | d.status.equals('failed') | d.status.equals('cancelled'))).go();

  // --- Listening History ---
  Future<int> recordListening(ListeningHistoryCompanion entry) => into(listeningHistory).insert(entry);
  Stream<List<ListeningEvent>> watchListeningHistory({int limit = 500}) =>
      (select(listeningHistory)..orderBy([(l) => OrderingTerm.desc(l.playedAt)])..limit(limit)).watch();
  Future<List<ListeningEvent>> getRecentHistory({int limit = 200}) =>
      (select(listeningHistory)..orderBy([(l) => OrderingTerm.desc(l.playedAt)])..limit(limit)).get();
  Future<Map<String, int>> getPlayCounts({int days = 30}) async {
    final since = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    final rows = await customSelect('''
      SELECT track_id, COUNT(*) as cnt
      FROM listening_history
      WHERE played_at > ?
      GROUP BY track_id
      ORDER BY cnt DESC
    ''', variables: [Variable.withInt(since)]).get();
    return {for (var r in rows) r.read<String>('track_id'): r.read<int>('cnt')};
  }
  Future<List<String>> getTopArtists({int days = 30, int limit = 20}) async {
    final since = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    final rows = await customSelect('''
      SELECT mt.artist, COUNT(*) as cnt
      FROM listening_history lh
      JOIN music_tracks mt ON mt.id = lh.track_id
      WHERE lh.played_at > ? AND mt.artist IS NOT NULL
      GROUP BY mt.artist
      ORDER BY cnt DESC
      LIMIT ?
    ''', variables: [Variable.withInt(since), Variable.withInt(limit)]).get();
    return rows.map((r) => r.read<String>('artist')).toList();
  }
  Future<List<String>> getTopGenres({int days = 30, int limit = 15}) async {
    final since = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    final rows = await customSelect('''
      SELECT mt.genre, COUNT(*) as cnt
      FROM listening_history lh
      JOIN music_tracks mt ON mt.id = lh.track_id
      WHERE lh.played_at > ? AND mt.genre IS NOT NULL
      GROUP BY mt.genre
      ORDER BY cnt DESC
      LIMIT ?
    ''', variables: [Variable.withInt(since), Variable.withInt(limit)]).get();
    return rows.map((r) => r.read<String>('genre')).toList();
  }
  Future<Map<String, int>> getListeningStats({int days = 7}) async {
    final since = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    final row = await customSelect('''
      SELECT 
        COUNT(*) as total_plays,
        COUNT(DISTINCT track_id) as unique_tracks,
        COUNT(DISTINCT artist) as unique_artists,
        COALESCE(SUM(duration_ms), 0) as total_ms
      FROM listening_history
      WHERE played_at > ?
    ''', variables: [Variable.withInt(since)]).getSingle();
    return {
      'totalPlays': row.read<int>('total_plays'),
      'uniqueTracks': row.read<int>('unique_tracks'),
      'uniqueArtists': row.read<int>('unique_artists'),
      'totalMs': row.read<int>('total_ms'),
    };
  }

  // --- Smart Playlist Generation ---
  Future<List<MusicTrack>> getRecommendations({int limit = 50, int days = 60}) async {
    final since = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    final rows = await customSelect('''
      SELECT DISTINCT mt.* FROM music_tracks mt
      WHERE mt.id NOT IN (
        SELECT track_id FROM listening_history WHERE played_at > ?
      )
      AND (mt.artist IN (
        SELECT artist FROM music_tracks
        WHERE id IN (SELECT track_id FROM listening_history WHERE played_at > ?)
        GROUP BY artist ORDER BY COUNT(*) DESC LIMIT 10
      ) OR mt.genre IN (
        SELECT genre FROM music_tracks
        WHERE id IN (SELECT track_id FROM listening_history WHERE played_at > ?)
        GROUP BY genre ORDER BY COUNT(*) DESC LIMIT 5
      ))
      ORDER BY mt.play_count DESC, mt.added_at DESC
      LIMIT ?
    ''', variables: [Variable.withInt(since), Variable.withInt(since), Variable.withInt(since), Variable.withInt(limit)],
    readsFrom: {musicTracks}).get();
    return rows.map((r) => _trackFromRow(r.data)).toList();
  }

  Future<List<MusicTrack>> getDiscoveryWeekly({int limit = 30}) async {
    final since = DateTime.now().subtract(const Duration(days: 90)).millisecondsSinceEpoch;
    final rows = await customSelect('''
      SELECT DISTINCT mt.* FROM music_tracks mt
      WHERE mt.id NOT IN (
        SELECT track_id FROM listening_history WHERE played_at > ?
      )
      AND mt.artist IN (
        SELECT artist FROM music_tracks
        WHERE id IN (SELECT track_id FROM listening_history WHERE played_at > ?)
        GROUP BY artist ORDER BY COUNT(*) DESC LIMIT 15
      )
      ORDER BY RANDOM()
      LIMIT ?
    ''', variables: [Variable.withInt(since), Variable.withInt(since), Variable.withInt(limit)],
    readsFrom: {musicTracks}).get();
    return rows.map((r) => _trackFromRow(r.data)).toList();
  }

  Future<List<MusicTrack>> getDailyMix({required String seed, int limit = 50}) async {
    final rows = await customSelect('''
      SELECT * FROM music_tracks
      WHERE (artist = ? OR genre = ?)
      ORDER BY play_count DESC, added_at DESC
      LIMIT ?
    ''', variables: [Variable.withString(seed), Variable.withString(seed), Variable.withInt(limit)],
    readsFrom: {musicTracks}).get();
    return rows.map((r) => _trackFromRow(r.data)).toList();
  }

  Future<List<MusicTrack>> getReleaseRadar({int limit = 30, int days = 14}) async {
    final since = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    final rows = await customSelect('''
      SELECT mt.* FROM music_tracks mt
      WHERE mt.added_at > ?
      AND mt.artist IN (
        SELECT DISTINCT artist FROM music_tracks
        WHERE id IN (SELECT track_id FROM listening_history WHERE played_at > ?)
      )
      ORDER BY mt.added_at DESC
      LIMIT ?
    ''', variables: [Variable.withInt(since), Variable.withInt(since), Variable.withInt(limit)],
    readsFrom: {musicTracks}).get();
    return rows.map((r) => _trackFromRow(r.data)).toList();
  }

  /// Generates a local/offline track radio playlist seeded by the given track's artist, genre or year.
  Future<List<MusicTrack>> getLocalTrackRadio({
    required String seedTrackId,
    String? artist,
    String? genre,
    int? year,
    int limit = 20,
  }) async {
    final cleanArtist = (artist ?? '').trim();
    final cleanGenre = (genre ?? '').trim();

    final matching = await customSelect('''
      SELECT DISTINCT mt.* FROM music_tracks mt
      WHERE mt.id != ?
      AND (
        (? != '' AND LOWER(mt.artist) = LOWER(?))
        OR (? != '' AND (LOWER(mt.genre) LIKE '%' || LOWER(?) || '%' OR LOWER(?) LIKE '%' || LOWER(mt.genre) || '%'))
      )
      ORDER BY 
        (CASE WHEN ? != '' AND LOWER(mt.artist) = LOWER(?) THEN 3 ELSE 0 END) +
        (CASE WHEN ? != '' AND LOWER(mt.genre) LIKE '%' || LOWER(?) || '%' THEN 2 ELSE 0 END) DESC,
        mt.play_count DESC,
        mt.added_at DESC
      LIMIT ?
    ''', variables: [
      Variable.withString(seedTrackId),
      Variable.withString(cleanArtist),
      Variable.withString(cleanArtist),
      Variable.withString(cleanGenre),
      Variable.withString(cleanGenre),
      Variable.withString(cleanGenre),
      Variable.withString(cleanArtist),
      Variable.withString(cleanArtist),
      Variable.withString(cleanGenre),
      Variable.withString(cleanGenre),
      Variable.withInt(limit),
    ], readsFrom: {musicTracks}).map((r) => _trackFromRow(r.data)).get();

    if (matching.length >= limit) {
      return matching;
    }

    final existingIds = {seedTrackId, ...matching.map((m) => m.id)};
    final remainingLimit = limit - matching.length;
    final remainingRows = await customSelect('''
      SELECT DISTINCT mt.* FROM music_tracks mt
      WHERE mt.id != ?
      ORDER BY mt.play_count DESC, mt.added_at DESC
      LIMIT ?
    ''', variables: [
      Variable.withString(seedTrackId),
      Variable.withInt(limit * 2),
    ], readsFrom: {musicTracks}).map((r) => _trackFromRow(r.data)).get();

    final backfill = <MusicTrack>[];
    for (final r in remainingRows) {
      if (!existingIds.contains(r.id)) {
        existingIds.add(r.id);
        backfill.add(r);
        if (backfill.length >= remainingLimit) break;
      }
    }

    return [...matching, ...backfill];
  }

  MusicTrack _trackFromRow(Map<String, dynamic> row) {
    return MusicTrack(
      id: row['id'] as String,
      title: row['title'] as String,
      artist: row['artist'] as String? ?? '',
      album: row['album'] as String? ?? '',
      albumArtist: row['album_artist'] as String? ?? '',
      trackNumber: (row['track_number'] as num?)?.toInt(),
      discNumber: (row['disc_number'] as num?)?.toInt(),
      year: (row['year'] as num?)?.toInt(),
      genre: row['genre'] as String? ?? '',
      filePath: row['file_path'] as String,
      lyricsPath: row['lyrics_path'] as String? ?? '',
      thumbnailUrl: row['thumbnail_url'] as String? ?? '',
      ytDlpId: row['yt_dlp_id'] as String? ?? '',
      duration: (row['duration'] as num?)?.toInt() ?? 0,
      bitrate: (row['bitrate'] as num?)?.toInt(),
      codec: row['codec'] as String? ?? '',
      replayGainTrack: (row['replay_gain_track'] as num?)?.toDouble(),
      replayGainAlbum: (row['replay_gain_album'] as num?)?.toDouble(),
      playCount: (row['play_count'] as num?)?.toInt() ?? 0,
      lastPlayedAt: (row['last_played_at'] as num?)?.toInt(),
      addedAt: (row['added_at'] as num?)?.toInt() ?? 0,
      updatedAt: (row['updated_at'] as num?)?.toInt() ?? 0,
      isDirty: (row['is_dirty'] as num?)?.toInt() ?? 0,
    );
  }
}