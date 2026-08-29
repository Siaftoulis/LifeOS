import 'dart:convert';
import 'package:drift/drift.dart';
import 'database.dart';
import 'tables.dart';

part 'transfer_dao.g.dart';

@DriftAccessor(tables: [FileTransfers, TransferChunks])
class TransferDao extends DatabaseAccessor<AppDatabase> with _$TransferDaoMixin {
  TransferDao(AppDatabase db) : super(db);

  Stream<List<FileTransfer>> watchAllTransfers() => select(fileTransfers).watch();

  Future<int> insertTransfer(FileTransfersCompanion entry) => into(fileTransfers).insert(entry);
  Future<int> insertOrUpdateTransfer(FileTransfersCompanion entry) => into(fileTransfers).insertOnConflictUpdate(entry);
  Future<List<FileTransfer>> getAllTransfers() => select(fileTransfers).get();
  Future<FileTransfer?> getTransfer(String transferId) => (select(fileTransfers)..where((t) => t.transferId.equals(transferId))).getSingleOrNull();
  Future<int> deleteTransfer(String transferId) => (delete(fileTransfers)..where((t) => t.transferId.equals(transferId))).go();
  Future<int> updateTransferState(String transferId, String state, {String? remoteFilePath}) {
    final companion = FileTransfersCompanion(
      state: Value(state),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      isDirty: const Value(1),
      remoteFilePath: remoteFilePath != null ? Value(remoteFilePath) : const Value.absent(),
    );
    return (update(fileTransfers)..where((t) => t.transferId.equals(transferId))).write(companion);
  }
  Future<int> updateTransferChunks(String transferId, List<int> received, List<int> verified) {
    final companion = FileTransfersCompanion(
      receivedChunks: Value(jsonEncode(received)),
      verifiedChunks: Value(jsonEncode(verified)),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      isDirty: const Value(1),
    );
    return (update(fileTransfers)..where((t) => t.transferId.equals(transferId))).write(companion);
  }

  Future<int> insertChunk(TransferChunksCompanion entry) => into(transferChunks).insert(entry);
  Future<int> insertOrUpdateChunk(TransferChunksCompanion entry) => into(transferChunks).insertOnConflictUpdate(entry);
  Future<List<TransferChunk>> getChunks(String transferId) => (select(transferChunks)..where((t) => t.transferId.equals(transferId))).get();
  Future<TransferChunk?> getChunk(String transferId, int chunkIndex) => (select(transferChunks)..where((t) => t.transferId.equals(transferId) & t.chunkIndex.equals(chunkIndex))).getSingleOrNull();
  Future<int> updateChunkState(String transferId, int chunkIndex, String state, {String? localPath, int? uploadedAt, int? verifiedAt, int? retryCount}) {
    final companion = TransferChunksCompanion(
      state: Value(state),
      localPath: localPath != null ? Value(localPath) : const Value.absent(),
      uploadedAt: uploadedAt != null ? Value(uploadedAt) : const Value.absent(),
      verifiedAt: verifiedAt != null ? Value(verifiedAt) : const Value.absent(),
      retryCount: retryCount != null ? Value(retryCount) : const Value.absent(),
      isDirty: const Value(1),
    );
    return (update(transferChunks)..where((t) => t.transferId.equals(transferId) & t.chunkIndex.equals(chunkIndex))).write(companion);
  }
  Future<int> deleteChunks(String transferId) => (delete(transferChunks)..where((t) => t.transferId.equals(transferId))).go();
}