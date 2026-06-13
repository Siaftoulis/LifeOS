import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'music_dao.g.dart';

@DriftAccessor(tables: [MusicTracks, Playlists, PlaylistTracks])
class MusicDao extends DatabaseAccessor<AppDatabase> with _$MusicDaoMixin {
  MusicDao(AppDatabase db) : super(db);

  Stream<List<MusicTrack>> watchAllTracks() => select(musicTracks).watch();
  Stream<List<Playlist>> watchPlaylists() => select(playlists).watch();
  
  Future<int> insertTrack(MusicTracksCompanion entry) => into(musicTracks).insert(entry);
  Future<int> insertPlaylist(PlaylistsCompanion entry) => into(playlists).insert(entry);
  Future<int> insertPlaylistTrack(PlaylistTracksCompanion entry) => into(playlistTracks).insert(entry);
}
