import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'youtube_dao.g.dart';

@DriftAccessor(tables: [YoutubeSessions, YoutubeDownloads])
class YoutubeDao extends DatabaseAccessor<AppDatabase> with _$YoutubeDaoMixin {
  YoutubeDao(AppDatabase db) : super(db);

  Stream<List<YoutubeSession>> watchSessions() => select(youtubeSessions).watch();
  Stream<List<YoutubeDownload>> watchDownloads() => select(youtubeDownloads).watch();

  Future<int> insertSession(YoutubeSessionsCompanion entry) => into(youtubeSessions).insert(entry);
  Future<int> insertDownload(YoutubeDownloadsCompanion entry) => into(youtubeDownloads).insert(entry);
}
