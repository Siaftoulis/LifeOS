import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'music_dao.g.dart';

@DriftAccessor(tables: [MusicTracks, Playlists, PlaylistTracks, OfflineMusicTracks])
class MusicDao extends DatabaseAccessor<AppDatabase> with _$MusicDaoMixin {
  MusicDao(AppDatabase db) : super(db);

  Stream<List<MusicTrack>> watchAllTracks() => select(musicTracks).watch();
  Stream<List<Playlist>> watchPlaylists() => select(playlists).watch();
  Stream<List<OfflineMusicTrack>> watchOfflineTracks() => select(offlineMusicTracks).watch();

  Future<List<OfflineMusicTrack>> getOfflineTracks() => select(offlineMusicTracks).get();
  Future<OfflineMusicTrack?> getOfflineTrack(String id) =>
      (select(offlineMusicTracks)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<int> insertOfflineTrack(OfflineMusicTracksCompanion entry) => into(offlineMusicTracks).insert(entry);
  Future<int> deleteOfflineTrack(String id) =>
      (delete(offlineMusicTracks)..where((t) => t.id.equals(id))).go();

  Future<int> insertTrack(MusicTracksCompanion entry) => into(musicTracks).insert(entry);
  Future<int> insertPlaylist(PlaylistsCompanion entry) => into(playlists).insert(entry);
  Future<int> insertPlaylistTrack(PlaylistTracksCompanion entry) => into(playlistTracks).insert(entry);
}
