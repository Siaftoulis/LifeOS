import 'package:drift/drift.dart';

@DataClassName('DeviceBackup')
class DeviceBackups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get lastBackup => integer()();
  TextColumn get storagePath => text()();
  TextColumn get backupStatus => text()();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BackupLog')
class BackupLogs extends Table {
  TextColumn get logId => text()();
  TextColumn get deviceId => text().customConstraint('NOT NULL REFERENCES device_backups(id) ON DELETE CASCADE')();
  IntColumn get timestamp => integer()();
  IntColumn get filesCount => integer()();
  IntColumn get bytesTransferred => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {logId};
}

@DataClassName('UploadQuarantine')
class UploadQuarantines extends Table {
  TextColumn get fileId => text()();
  TextColumn get fileName => text()();
  IntColumn get fileSize => integer()();
  TextColumn get scanStatus => text().withDefault(const Constant('PENDING'))();
  IntColumn get createdAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {fileId};
}

@DataClassName('Torrent')
class Torrents extends Table {
  TextColumn get id => text()();
  TextColumn get infoHash => text().customConstraint('NOT NULL UNIQUE')();
  TextColumn get name => text()();
  IntColumn get sizeBytes => integer()();
  RealColumn get progress => real().withDefault(const Constant(0.0))();
  IntColumn get downloadSpeed => integer().withDefault(const Constant(0))();
  IntColumn get uploadSpeed => integer().withDefault(const Constant(0))();
  TextColumn get status => text()();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TorrentPeer')
class TorrentPeers extends Table {
  TextColumn get id => text()();
  TextColumn get torrentId => text().customConstraint('NOT NULL REFERENCES torrents(id) ON DELETE CASCADE')();
  TextColumn get clientIp => text()();
  IntColumn get bytesExchanged => integer().withDefault(const Constant(0))();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SharedFile')
class SharedFiles extends Table {
  TextColumn get id => text()();
  TextColumn get filePath => text()();
  TextColumn get name => text()();
  IntColumn get sizeBytes => integer()();
  TextColumn get status => text().withDefault(const Constant('PENDING'))();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

