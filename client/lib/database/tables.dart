import 'package:drift/drift.dart';

class LifeEntities extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  
  // Mandatory tracking fields
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get syncedAt => integer().nullable()();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  
  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get targetTable => text()();
  TextColumn get recordId => text()();
  TextColumn get fieldName => text()();
  TextColumn get oldValue => text().nullable()();
  TextColumn get newValue => text().nullable()();
  
  // Synchronization markers
  IntColumn get clientUpdatedAt => integer()();
  IntColumn get syncedState => integer().withDefault(const Constant(0))();
  
  @override
  Set<Column> get primaryKey => {id};
}

class SystemSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {key};
}

class UserProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get username => text()();
  TextColumn get role => text()(); // 'ADMIN', 'NORMAL', 'CHILD'
  IntColumn get dailyLimit => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MarkdownNote')
class MarkdownNotes extends Table {
  TextColumn get id => text()();
  TextColumn get filePath => text().customConstraint('NOT NULL UNIQUE')();
  TextColumn get frontmatterJson => text().nullable()();
  IntColumn get lastModified => integer()();
  TextColumn get hash => text()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('NotesIndex')
class NotesIndices extends Table {
  TextColumn get id => text().customConstraint('NOT NULL REFERENCES markdown_notes(id) ON DELETE CASCADE')();
  IntColumn get wordCount => integer().withDefault(const Constant(0))();
  TextColumn get referencesList => text().nullable()(); // COMMA separated links IDs
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AccountingCredential')
class AccountingCredentials extends Table {
  TextColumn get id => text()(); // UUID string
  TextColumn get label => text()(); // e.g., 'Taxisnet', 'AFM', 'AMKA'
  BlobColumn get encryptedUsername => blob().nullable()(); // AES-GCM encrypted
  BlobColumn get encryptedPassword => blob().nullable()(); // AES-GCM encrypted
  IntColumn get updatedAt => integer()(); // Unix millisecond timestamp
  IntColumn get syncedAt => integer().nullable()(); // Nullable sync timestamp
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AccountingDocument')
class AccountingDocuments extends Table {
  TextColumn get id => text()(); // UUID string
  TextColumn get title => text()(); // e.g., 'ID Card Scan 2026'
  TextColumn get encryptedFilepath => text()(); // Encrypted local relative path
  TextColumn get fileExtension => text()(); // e.g., 'pdf', 'png'
  IntColumn get updatedAt => integer()(); // Unix millisecond timestamp
  IntColumn get syncedAt => integer().nullable()(); // Nullable sync timestamp
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BankAccount')
class BankAccounts extends Table {
  TextColumn get id => text()(); // UUID string
  TextColumn get name => text()(); // e.g., 'Primary Eurobank', 'Bills Saver'
  IntColumn get balanceCents => integer()(); // Account balance in cents
  IntColumn get updatedAt => integer()(); // Unix millisecond timestamp
  IntColumn get syncedAt => integer().nullable()(); // Nullable sync timestamp
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BankLedger')
class BankLedgers extends Table {
  TextColumn get id => text()(); // UUID string
  TextColumn get accountId => text().customConstraint('NOT NULL REFERENCES bank_accounts(id)')();
  IntColumn get amountCents => integer()(); // Signed integer cents (positive = credit, negative = debit)
  TextColumn get transactionType => text()(); // e.g., 'Groceries', 'Allowance', 'Bills'
  IntColumn get dateTimestamp => integer()(); // Transaction date stamp
  TextColumn get description => text().nullable()(); // Optional description
  IntColumn get updatedAt => integer()(); // Unix millisecond timestamp
  IntColumn get syncedAt => integer().nullable()(); // Nullable sync timestamp
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BillLog')
class BillLogs extends Table {
  TextColumn get id => text()(); // UUID string
  TextColumn get provider => text()(); // e.g., 'DEI', 'Cosmote'
  IntColumn get amountCents => integer()(); // Bill cost in cents
  IntColumn get dueDate => integer()(); // Unix timestamp due date
  IntColumn get updatedAt => integer()(); // Unix millisecond timestamp

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BankingRollover')
class BankingRollovers extends Table {
  TextColumn get key => text()(); // e.g., 'bills_carry_over'
  IntColumn get surplusCents => integer()(); // Surplus amount in cents
  IntColumn get updatedAt => integer()(); // Unix millisecond timestamp

  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('Book')
class Books extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get author => text().nullable()();
  IntColumn get currentPage => integer().withDefault(const Constant(0))();
  IntColumn get totalPages => integer().withDefault(const Constant(0))();
  TextColumn get filePath => text()();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Audiobook')
class Audiobooks extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text().customConstraint('NOT NULL REFERENCES books(id) ON DELETE CASCADE')();
  TextColumn get filePath => text()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  IntColumn get currentSeconds => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class ReadingProgress extends Table {
  TextColumn get bookId => text().customConstraint('NOT NULL REFERENCES books(id) ON DELETE CASCADE')();
  IntColumn get page => integer().withDefault(const Constant(0))();
  IntColumn get seconds => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer()();
  IntColumn get syncedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {bookId};
}

@DataClassName('BookHighlight')
class BookHighlights extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text().customConstraint('NOT NULL REFERENCES books(id) ON DELETE CASCADE')();
  TextColumn get textContent => text()();
  TextColumn get noteContent => text().nullable()();
  IntColumn get pageNumber => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CalendarEvent')
class CalendarEvents extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get startTime => integer()();
  IntColumn get endTime => integer()();
  TextColumn get colorCode => text().withDefault(const Constant('#89B4FA'))();
  IntColumn get isShared => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('UserTask')
class UserTasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(1))();
  TextColumn get status => text().withDefault(const Constant('TODO'))();
  IntColumn get dueDate => integer().nullable()();
  IntColumn get completedAt => integer().nullable()();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('UserHabit')
class UserHabits extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get frequencyCron => text()();
  IntColumn get targetStreak => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('HabitLog')
class HabitLogs extends Table {
  TextColumn get id => text()();
  TextColumn get habitId => text().customConstraint('NOT NULL REFERENCES user_habits(id) ON DELETE CASCADE')();
  IntColumn get checkinDate => integer()();
  IntColumn get pointsAwarded => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

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

@DataClassName('FlashcardDeck')
class FlashcardDecks extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get createdAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Flashcard')
class Flashcards extends Table {
  TextColumn get id => text()();
  TextColumn get deckId => text().customConstraint('NOT NULL REFERENCES flashcard_decks(id) ON DELETE CASCADE')();
  TextColumn get question => text()();
  TextColumn get answer => text()();
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get nextReview => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('FlashcardReview')
class FlashcardReviews extends Table {
  TextColumn get id => text()();
  TextColumn get cardId => text().customConstraint('NOT NULL REFERENCES flashcards(id) ON DELETE CASCADE')();
  IntColumn get timestamp => integer()();
  IntColumn get quality => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SmartDevice')
class SmartDevices extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'LIGHT', 'SWITCH', 'THERMOSTAT', 'APPLIANCE'
  TextColumn get state => text()(); // 'ON', 'OFF', 'UNKNOWN'
  TextColumn get room => text().nullable()();
  IntColumn get lastUpdated => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('EnvironmentLog')
class EnvironmentLogs extends Table {
  TextColumn get id => text()();
  TextColumn get sensorId => text()();
  RealColumn get temperature => real().nullable()();
  RealColumn get humidity => real().nullable()();
  IntColumn get timestamp => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DeviceSchedule')
class DeviceSchedules extends Table {
  TextColumn get id => text()();
  TextColumn get deviceId => text().customConstraint('NOT NULL REFERENCES smart_devices(id) ON DELETE CASCADE')();
  TextColumn get action => text()(); // 'TURN_ON', 'TURN_OFF'
  TextColumn get cronExpression => text()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SystemUser')
class SystemUsers extends Table {
  TextColumn get id => text()();
  TextColumn get username => text()();
  TextColumn get passwordHash => text().nullable()();
  IntColumn get isLocked => integer().withDefault(const Constant(1))();
  IntColumn get failedAttempts => integer().withDefault(const Constant(0))();
  IntColumn get currentPoints => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocalNotification')
class LocalNotifications extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get message => text()();
  TextColumn get category => text()(); // 'SYSTEM', 'HABIT', 'SECURITY', 'FINANCIAL'
  IntColumn get readAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('KnowledgeTopic')
class KnowledgeTopics extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get category => text()(); // 'TECH', 'SCIENCE', 'PHILOSOPHY', 'HISTORY'
  TextColumn get status => text()(); // 'LEARNING', 'COMPLETED', 'BACKLOG'
  TextColumn get notePath => text().customConstraint('NOT NULL UNIQUE')();
  IntColumn get lastStudied => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('KnowledgeRelationship')
class KnowledgeRelationships extends Table {
  TextColumn get id => text()();
  TextColumn get sourceId => text().customConstraint('NOT NULL REFERENCES knowledge_topics(id) ON DELETE CASCADE')();
  TextColumn get targetId => text().customConstraint('NOT NULL REFERENCES knowledge_topics(id) ON DELETE CASCADE')();
  TextColumn get relationType => text()(); // 'REQUIRES', 'EXPANDS', 'CONTRADICTS'
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Geofence')
class Geofences extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get radius => real()();
  IntColumn get isActive => integer().withDefault(const Constant(1))();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocationLog')
class LocationLogs extends Table {
  TextColumn get id => text()();
  TextColumn get deviceId => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get velocity => real().nullable()();
  RealColumn get altitude => real().nullable()();
  IntColumn get timestamp => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Bookmark')
class Bookmarks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  IntColumn get createdAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Movie')
class Movies extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get imdbId => text().nullable()();
  TextColumn get coverPath => text().nullable()();
  TextColumn get filePath => text()();
  TextColumn get status => text()(); // 'AVAILABLE', 'DOWNLOADING', 'WATCHED'
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MovieWatchlist')
class MovieWatchlists extends Table {
  TextColumn get id => text()();
  TextColumn get movieId => text().customConstraint('NOT NULL REFERENCES movies(id) ON DELETE CASCADE')();
  IntColumn get addedAt => integer()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MovieReview')
class MovieReviews extends Table {
  TextColumn get id => text()();
  TextColumn get movieId => text().customConstraint('NOT NULL REFERENCES movies(id) ON DELETE CASCADE')();
  RealColumn get rating => real().withDefault(const Constant(0.0))();
  TextColumn get comment => text().nullable()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MusicTrack')
class MusicTracks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  IntColumn get trackNumber => integer().nullable()();
  TextColumn get filePath => text()();
  TextColumn get lyricsPath => text().nullable()();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Playlist')
class Playlists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get createdAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PlaylistTrack')
class PlaylistTracks extends Table {
  TextColumn get id => text()();
  TextColumn get playlistId => text().customConstraint('NOT NULL REFERENCES playlists(id) ON DELETE CASCADE')();
  TextColumn get trackId => text().customConstraint('NOT NULL REFERENCES music_tracks(id) ON DELETE CASCADE')();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}


@DataClassName('MediaAsset')
class MediaAssets extends Table {
  TextColumn get id => text()();
  TextColumn get filename => text()();
  TextColumn get filePath => text().customConstraint('NOT NULL UNIQUE')();
  IntColumn get fileSize => integer()();
  TextColumn get fileType => text()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  IntColumn get captureTime => integer()();
  TextColumn get scanStatus => text().withDefault(const Constant('PENDING'))();
  IntColumn get updatedAt => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MediaTag')
class MediaTags extends Table {
  TextColumn get id => text()();
  TextColumn get assetId => text().customConstraint('NOT NULL REFERENCES media_assets(id) ON DELETE CASCADE')();
  TextColumn get tagName => text()();
  TextColumn get tagType => text()();
  RealColumn get confidence => real().withDefault(const Constant(1.0))();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}


@DataClassName('PointRule')
class PointRules extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get module => text()();
  IntColumn get pointsValue => integer()();
  IntColumn get isDirty => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

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

@DataClassName('VirtualMachine')
class VirtualMachines extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get state => text()();
  IntColumn get cpuLimit => integer().withDefault(const Constant(1))();
  IntColumn get ramLimit => integer().withDefault(const Constant(512))();
  IntColumn get updatedAt => integer()();
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
