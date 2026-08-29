import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../../api_client.dart';
import '../../database/database.dart';
import '../../database/transfer_dao.dart';
import 'transfer_models.dart';

class FileTransferService {
  static final FileTransferService instance = FileTransferService._internal();
  FileTransferService._internal();

  static const int _maxConcurrentChunks = 4;
  static const Duration _chunkTimeout = Duration(minutes: 5);
  static const Duration _initTimeout = Duration(seconds: 30);
  static const Duration _statusTimeout = Duration(seconds: 10);

  final ValueNotifier<TransferProgress?> progressNotifier = ValueNotifier(null);
  final ValueNotifier<Map<String, TransferProgress>> activeTransfersNotifier = ValueNotifier({});

  TransferDao get _dao => TransferDao(AppDatabase.instance);

  String get _baseUrl => '${ApiClient.instance.daemonUrl}/api/v1/transfer';

  Future<TransferInitResponse?> initTransfer({
    required String filePath,
    int? chunkSize,
    String? mimeType,
    Map<String, dynamic>? metadata,
    Function(TransferProgress)? onProgress,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      debugPrint('File not found: $filePath');
      return null;
    }

    final fileSize = await file.length();
    if (fileSize == 0) {
      debugPrint('File is empty: $filePath');
      return null;
    }

    final fileHash = await _computeFileHash(file);
    final fileId = _generateFileId(filePath, fileSize, fileHash);
    final effectiveChunkSize = ChunkSizeStrategy.calculateChunkSize(fileSize: fileSize, preferredSize: chunkSize);
    final totalChunks = (fileSize / effectiveChunkSize).ceil();

    final transferId = _generateTransferId();

    final now = DateTime.now().millisecondsSinceEpoch;
    await _dao.insertTransfer(FileTransfersCompanion(
      transferId: Value(transferId),
      fileId: Value(fileId),
      fileName: Value(p.basename(filePath)),
      fileSize: Value(fileSize),
      fileHash: Value(fileHash),
      chunkSize: Value(effectiveChunkSize),
      totalChunks: Value(totalChunks),
      receivedChunks: const Value('[]'),
      verifiedChunks: const Value('[]'),
      state: Value(TransferState.preparing.name),
      mimeType: Value(mimeType),
      metadata: metadata != null ? Value(jsonEncode(metadata)) : const Value.absent(),
      localFilePath: Value(filePath),
      createdAt: Value(now),
      updatedAt: Value(now),
      isDirty: const Value(1),
    ));

    for (int i = 0; i < totalChunks; i++) {
      final offset = i * effectiveChunkSize;
      final length = min(effectiveChunkSize, fileSize - offset);
      final chunkHash = await _computeChunkHash(file, offset, length);
      
      await _dao.insertChunk(TransferChunksCompanion(
        transferId: Value(transferId),
        chunkIndex: Value(i),
        offset: Value(offset),
        length: Value(length),
        hash: Value(chunkHash),
        state: Value(ChunkState.pending.name),
        retryCount: const Value(0),
        isDirty: const Value(1),
      ));
    }

    final initReq = TransferInitRequest(
      fileId: fileId,
      fileName: p.basename(filePath),
      fileSize: fileSize,
      fileHash: fileHash,
      chunkSize: effectiveChunkSize,
      mimeType: mimeType,
      metadata: metadata,
    );

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/init'),
        headers: ApiClient.instance.transferHeaders,
        body: jsonEncode(initReq.toJson()),
      ).timeout(_initTimeout);

      if (response.statusCode != 200) {
        await _dao.updateTransferState(transferId, TransferState.failed.value);
        return null;
      }

      final data = jsonDecode(response.body);
      final initResp = TransferInitResponse.fromJson(data);

      await _dao.updateTransferState(transferId, TransferState.transferring.value);

      return initResp;
    } catch (e) {
      debugPrint('Init transfer failed: $e');
      await _dao.updateTransferState(transferId, TransferState.interrupted.value);
      return null;
    }
  }

  Future<bool> uploadChunks({
    required String transferId,
    required List<int> chunkIndices,
    Function(TransferProgress)? onProgress,
  }) async {
    final transfer = await _dao.getTransfer(transferId);
    if (transfer == null) return false;

    final file = File(transfer.localFilePath!);
    if (!await file.exists()) {
      debugPrint('Local file not found: ${transfer.localFilePath}');
      return false;
    }

    final semaphore = _Semaphore(_maxConcurrentChunks);
    final futures = <Future<bool>>[];

    for (final chunkIndex in chunkIndices) {
      await semaphore.acquire();
      futures.add(_uploadChunk(transfer, file, chunkIndex, semaphore, onProgress));
    }

    final results = await Future.wait(futures);
    return results.every((r) => r);
  }

  Future<bool> _uploadChunk(
    FileTransfer transfer,
    File file,
    int chunkIndex,
    _Semaphore semaphore,
    Function(TransferProgress)? onProgress,
  ) async {
    try {
      final chunk = await _dao.getChunk(transfer.transferId, chunkIndex);
      if (chunk == null) return false;

      await _dao.updateChunkState(transfer.transferId, chunkIndex, ChunkState.uploading.value);

      final chunkData = await _readChunk(file, chunk.offset, chunk.length);
      final computedHash = _computeHash(chunkData);
      
      if (computedHash != chunk.hash) {
        debugPrint('Chunk $chunkIndex hash mismatch locally');
        await _dao.updateChunkState(transfer.transferId, chunkIndex, ChunkState.failed.value, retryCount: chunk.retryCount + 1);
        return false;
      }

      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/chunk'));
      request.fields['transfer_id'] = transfer.transferId;
      request.fields['chunk_index'] = chunkIndex.toString();
      request.fields['offset'] = chunk.offset.toString();
      request.fields['length'] = chunk.length.toString();
      request.fields['hash'] = chunk.hash;
      request.files.add(http.MultipartFile.fromBytes('chunk', chunkData, filename: 'chunk_$chunkIndex'));

      final streamedResponse = await request.send().timeout(_chunkTimeout);
      final responseBody = await streamedResponse.stream.bytesToString();
      final data = jsonDecode(responseBody);
      final resp = ChunkUploadResponse.fromJson(data);

      if (!resp.success) {
        debugPrint('Chunk $chunkIndex upload failed: ${resp.error}');
        await _dao.updateChunkState(transfer.transferId, chunkIndex, ChunkState.failed.value, retryCount: chunk.retryCount + 1);
        return false;
      }

      await _dao.updateChunkState(
        transfer.transferId,
        chunkIndex,
        resp.verified ? ChunkState.verified.value : ChunkState.uploaded.value,
        uploadedAt: DateTime.now().millisecondsSinceEpoch,
        verifiedAt: resp.verified ? DateTime.now().millisecondsSinceEpoch : null,
      );

      _emitProgress(transfer, onProgress);
      return true;
    } catch (e) {
      debugPrint('Chunk $chunkIndex upload error: $e');
      final chunk = await _dao.getChunk(transfer.transferId, chunkIndex);
      if (chunk != null) {
        await _dao.updateChunkState(transfer.transferId, chunkIndex, ChunkState.failed.value, retryCount: chunk.retryCount + 1);
      }
      return false;
    } finally {
      semaphore.release();
    }
  }

  Future<TransferStatusResponse?> getStatus(String transferId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/status?transfer_id=$transferId'),
        headers: ApiClient.instance.transferHeaders,
      ).timeout(_statusTimeout);

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      return TransferStatusResponse.fromJson(data);
    } catch (e) {
      debugPrint('Get status failed: $e');
      return null;
    }
  }

  Future<bool> resumeTransfer(String transferId, Function(TransferProgress)? onProgress) async {
    final status = await getStatus(transferId);
    if (status == null) return false;

    if (status.missingChunks.isEmpty) {
      return await verifyTransfer(transferId);
    }

    await _dao.updateTransferState(transferId, TransferState.transferring.value);

    final success = await uploadChunks(
      transferId: transferId,
      chunkIndices: status.missingChunks,
      onProgress: onProgress,
    );

    if (!success) {
      await _dao.updateTransferState(transferId, TransferState.retrying.value);
      return false;
    }

    return await verifyTransfer(transferId);
  }

  Future<bool> verifyTransfer(String transferId) async {
    final transfer = await _dao.getTransfer(transferId);
    if (transfer == null) return false;

    await _dao.updateTransferState(transferId, TransferState.verifying.value);

    try {
      final verifyReq = TransferVerifyRequest(
        transferId: transferId,
        expectedFileHash: transfer.fileHash,
      );

      final response = await http.post(
        Uri.parse('$_baseUrl/verify'),
        headers: ApiClient.instance.transferHeaders,
        body: jsonEncode(verifyReq.toJson()),
      ).timeout(const Duration(minutes: 5));

      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body);
      final resp = TransferVerifyResponse.fromJson(data);

      if (!resp.success || !resp.hashesMatch) {
        debugPrint('Verification failed: ${resp.error}');
        await _dao.updateTransferState(transferId, TransferState.failed.value);
        return false;
      }

      final localHash = await _computeFileHash(File(transfer.localFilePath!));
      if (localHash != transfer.fileHash) {
        debugPrint('Local file hash changed during transfer');
        await _dao.updateTransferState(transferId, TransferState.failed.value);
        return false;
      }

      await _dao.updateTransferState(transferId, TransferState.completed.value, remoteFilePath: resp.actualHash);
      _emitProgress(transfer, null);
      return true;
    } catch (e) {
      debugPrint('Verify transfer failed: $e');
      await _dao.updateTransferState(transferId, TransferState.failed.value);
      return false;
    }
  }

  Future<bool> completeTransfer(String transferId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/complete'),
        headers: ApiClient.instance.transferHeaders,
        body: jsonEncode({'transfer_id': transferId}),
      ).timeout(_statusTimeout);

      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body);
      final resp = TransferCompleteResponse.fromJson(data);
      return resp.success;
    } catch (e) {
      debugPrint('Complete transfer failed: $e');
      return false;
    }
  }

  Future<void> cancelTransfer(String transferId) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/cancel'),
        headers: ApiClient.instance.transferHeaders,
        body: jsonEncode({'transfer_id': transferId}),
      ).timeout(_statusTimeout);
    } catch (e) {
      debugPrint('Cancel transfer failed: $e');
    }
    await _dao.updateTransferState(transferId, TransferState.cancelled.value);
    await _dao.deleteChunks(transferId);
    _emitProgress(null, null);
  }

  Future<String?> downloadFile(String transferId, String destinationPath) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/stream?transfer_id=$transferId'),
        headers: ApiClient.instance.transferHeaders,
      ).timeout(const Duration(minutes: 10));

      if (response.statusCode != 200) return null;

      final file = File(destinationPath);
      await file.writeAsBytes(response.bodyBytes);
      return destinationPath;
    } catch (e) {
      debugPrint('Download file failed: $e');
      return null;
    }
  }

  Future<bool> _emitProgress(FileTransfer? transfer, Function(TransferProgress)? onProgress) async {
    if (transfer == null) {
      progressNotifier.value = null;
      return false;
    }

    final chunks = await _dao.getChunks(transfer.transferId);
    final uploaded = chunks.where((c) => c.state == ChunkState.uploaded.value || c.state == ChunkState.verified.value).length;
    final verified = chunks.where((c) => c.state == ChunkState.verified.value).length;
    final failed = chunks.where((c) => c.state == ChunkState.failed.value).length;
    final retransmitted = chunks.fold<int>(0, (sum, c) => sum + c.retryCount);

    final state = TransferState.fromString(transfer.state);
    final progress = TransferProgress(
      transferId: transfer.transferId,
      fileName: transfer.fileName,
      fileSize: transfer.fileSize,
      bytesTransferred: (transfer.fileSize * uploaded / transfer.totalChunks).round(),
      totalChunks: transfer.totalChunks,
      chunksCompleted: uploaded,
      chunksVerified: verified,
      chunksFailed: failed,
      chunksRetransmitted: retransmitted,
      speedBytesPerSecond: 0.0,
      state: state,
      updatedAt: DateTime.now(),
    );

    progressNotifier.value = progress;
    final active = Map<String, TransferProgress>.from(activeTransfersNotifier.value);
    active[transfer.transferId] = progress;
    activeTransfersNotifier.value = active;

    if (onProgress != null) {
      onProgress(progress);
    }
    return true;
  }

  Future<String> _computeFileHash(File file) async {
    final bytes = await file.readAsBytes();
    return _computeHash(bytes);
  }

  String _computeHash(List<int> bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<String> _computeChunkHash(File file, int offset, int length) async {
    final chunkData = await _readChunk(file, offset, length);
    return _computeHash(chunkData);
  }

  Future<List<int>> _readChunk(File file, int offset, int length) async {
    final randomAccessFile = await file.open(mode: FileMode.read);
    final chunkData = List<int>.filled(length, 0);
    await randomAccessFile.readInto(chunkData, 0, offset);
    await randomAccessFile.close();
    return chunkData;
  }

  String _generateFileId(String filePath, int fileSize, String fileHash) {
    return '${p.basename(filePath)}_${fileSize}_${fileHash.substring(0, 8)}';
  }

  String _generateTransferId() {
    return 'xfer_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  Future<List<FileTransfer>> getLocalTransfers() async {
    return await _dao.getAllTransfers();
  }

  Future<FileTransfer?> getTransfer(String transferId) async {
    return await _dao.getTransfer(transferId);
  }

  Future<void> cleanupCompletedTransfers({Duration olderThan = const Duration(days: 7)}) async {
    final cutoff = DateTime.now().subtract(olderThan).millisecondsSinceEpoch;
    final transfers = await _dao.getAllTransfers();
    for (final t in transfers) {
      if (t.state == TransferState.completed.value && t.updatedAt < cutoff) {
        await _dao.deleteTransfer(t.transferId);
      }
    }
  }
}

class _Semaphore {
  final int _max;
  int _current = 0;
  final List<Completer<void>> _waiters = [];

  _Semaphore(this._max);

  Future<void> acquire() async {
    if (_current < _max) {
      _current++;
      return;
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    return completer.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    } else {
      _current--;
    }
  }
}