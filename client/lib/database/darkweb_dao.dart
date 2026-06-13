import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'darkweb_dao.g.dart';

@DriftAccessor(tables: [Torrents, TorrentPeers, SharedFiles])
class DarkWebDao extends DatabaseAccessor<AppDatabase> with _$DarkWebDaoMixin {
  DarkWebDao(AppDatabase db) : super(db);

  Stream<List<Torrent>> watchAllTorrents() => select(torrents).watch();
  Stream<List<TorrentPeer>> watchPeers(String torrentId) =>
      (select(torrentPeers)..where((t) => t.torrentId.equals(torrentId))).watch();
  Stream<List<SharedFile>> watchSharedFiles() => select(sharedFiles).watch();

  Future<int> insertTorrent(TorrentsCompanion entry) => into(torrents).insert(entry);
  Future<int> insertSharedFile(SharedFilesCompanion entry) => into(sharedFiles).insert(entry);
}
