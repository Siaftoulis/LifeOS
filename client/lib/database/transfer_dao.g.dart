// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_dao.dart';

// ignore_for_file: type=lint
mixin _$TransferDaoMixin on DatabaseAccessor<AppDatabase> {
  $FileTransfersTable get fileTransfers => attachedDatabase.fileTransfers;
  $TransferChunksTable get transferChunks => attachedDatabase.transferChunks;
  TransferDaoManager get managers => TransferDaoManager(this);
}

class TransferDaoManager {
  final _$TransferDaoMixin _db;
  TransferDaoManager(this._db);
  $$FileTransfersTableTableManager get fileTransfers =>
      $$FileTransfersTableTableManager(_db.attachedDatabase, _db.fileTransfers);
  $$TransferChunksTableTableManager get transferChunks =>
      $$TransferChunksTableTableManager(
          _db.attachedDatabase, _db.transferChunks);
}
