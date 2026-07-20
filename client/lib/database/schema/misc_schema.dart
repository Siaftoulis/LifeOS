import 'package:drift/drift.dart';

@DataClassName('PointsLedger')
class PointsLedgers extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().customConstraint('NOT NULL REFERENCES system_users(id) ON DELETE CASCADE')();
  TextColumn get event => text()();
  IntColumn get points => integer()();
  IntColumn get timestamp => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Voucher')
class Vouchers extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get costPoints => integer()();
  IntColumn get isRedeemed => integer().withDefault(const Constant(0))();
  TextColumn get redeemedBy => text().nullable()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DailyWord')
class DailyWords extends Table {
  TextColumn get id => text()();
  TextColumn get greekWord => text()();
  TextColumn get englishTranslation => text()();
  TextColumn get greekDefinition => text().nullable()();
  TextColumn get englishDefinition => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DailyTrivia')
class DailyTrivias extends Table {
  TextColumn get id => text()();
  TextColumn get factText => text()();
  TextColumn get sourceUrl => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RemoteSession')
class RemoteSessions extends Table {
  TextColumn get id => text()();
  TextColumn get hostDevice => text()();
  TextColumn get clientDevice => text()();
  IntColumn get streamPort => integer()();
  IntColumn get isActive => integer().withDefault(const Constant(1))();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('YoutubeSession')
class YoutubeSessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  IntColumn get startTime => integer()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  IntColumn get costPoints => integer().withDefault(const Constant(0))();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('YoutubeDownload')
class YoutubeDownloads extends Table {
  TextColumn get id => text()();
  TextColumn get videoId => text().customConstraint('UNIQUE NOT NULL')();
  TextColumn get title => text()();
  TextColumn get filePath => text()();
  IntColumn get sizeBytes => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ZenNode')
class ZenNodes extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text()(); // e.g., 'My Note.md' or 'MyFolder'
  TextColumn get path => text().customConstraint('UNIQUE NOT NULL')(); // Vault relative path e.g., '/MyFolder/My Note.md'
  IntColumn get isDirectory => integer().withDefault(const Constant(0))(); // 0 or 1
  TextColumn get parentId => text().nullable()(); // UUID of parent ZenNode
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ZenDocument')
class ZenDocuments extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get nodeId => text().customConstraint('NOT NULL REFERENCES zen_nodes(id) ON DELETE CASCADE')();
  TextColumn get textContent => text()(); // The actual markdown text or CRDT state
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

