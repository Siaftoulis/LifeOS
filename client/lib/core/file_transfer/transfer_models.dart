import 'package:drift/drift.dart';

enum TransferState {
  created('CREATED'),
  preparing('PREPARING'),
  transferring('TRANSFERRING'),
  verifying('VERIFYING'),
  completed('COMPLETED'),
  paused('PAUSED'),
  interrupted('INTERRUPTED'),
  retrying('RETRYING'),
  failed('FAILED'),
  cancelled('CANCELLED');

  const TransferState(this.value);
  final String value;

  static TransferState fromString(String s) {
    return TransferState.values.firstWhere((e) => e.value == s, orElse: () => TransferState.created);
  }
}

enum ChunkState {
  pending('PENDING'),
  uploading('UPLOADING'),
  uploaded('UPLOADED'),
  verified('VERIFIED'),
  failed('FAILED');

  const ChunkState(this.value);
  final String value;

  static ChunkState fromString(String s) {
    return ChunkState.values.firstWhere((e) => e.value == s, orElse: () => ChunkState.pending);
  }
}

class TransferMetadata {
  final String transferId;
  final String fileId;
  final String fileName;
  final int fileSize;
  final String fileHash;
  final int chunkSize;
  final int totalChunks;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final TransferState state;
  final String? mimeType;
  final Map<String, dynamic>? metadata;

  TransferMetadata({
    required this.transferId,
    required this.fileId,
    required this.fileName,
    required this.fileSize,
    required this.fileHash,
    required this.chunkSize,
    required this.totalChunks,
    required this.createdAt,
    this.updatedAt,
    required this.state,
    this.mimeType,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'transfer_id': transferId,
    'file_id': fileId,
    'filename': fileName,
    'file_size': fileSize,
    'file_hash': fileHash,
    'chunk_size': chunkSize,
    'total_chunks': totalChunks,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'state': state.value,
    'mime_type': mimeType,
    'metadata': metadata,
  };

  factory TransferMetadata.fromJson(Map<String, dynamic> json) => TransferMetadata(
    transferId: json['transfer_id'] as String,
    fileId: json['file_id'] as String,
    fileName: json['filename'] as String,
    fileSize: json['file_size'] as int,
    fileHash: json['file_hash'] as String,
    chunkSize: json['chunk_size'] as int,
    totalChunks: json['total_chunks'] as int,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    state: TransferState.fromString(json['state'] as String),
    mimeType: json['mime_type'] as String?,
    metadata: json['metadata'] as Map<String, dynamic>?,
  );
}

class ChunkInfo {
  final String transferId;
  final int chunkIndex;
  final int offset;
  final int length;
  final String hash;
  final ChunkState state;
  final int? uploadedAt;
  final int retryCount;

  ChunkInfo({
    required this.transferId,
    required this.chunkIndex,
    required this.offset,
    required this.length,
    required this.hash,
    required this.state,
    this.uploadedAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'transfer_id': transferId,
    'chunk_index': chunkIndex,
    'offset': offset,
    'length': length,
    'hash': hash,
    'state': state.value,
    'uploaded_at': uploadedAt,
    'retry_count': retryCount,
  };

  factory ChunkInfo.fromJson(Map<String, dynamic> json) => ChunkInfo(
    transferId: json['transfer_id'] as String,
    chunkIndex: json['chunk_index'] as int,
    offset: json['offset'] as int,
    length: json['length'] as int,
    hash: json['hash'] as String,
    state: ChunkState.fromString(json['state'] as String),
    uploadedAt: json['uploaded_at'] as int?,
    retryCount: json['retry_count'] as int? ?? 0,
  );
}

class TransferProgress {
  final String transferId;
  final String fileName;
  final int fileSize;
  final int bytesTransferred;
  final int totalChunks;
  final int chunksCompleted;
  final int chunksVerified;
  final int chunksFailed;
  final int chunksRetransmitted;
  final double speedBytesPerSecond;
  final Duration? eta;
  final TransferState state;
  final String? errorMessage;
  final DateTime updatedAt;

  TransferProgress({
    required this.transferId,
    required this.fileName,
    required this.fileSize,
    required this.bytesTransferred,
    required this.totalChunks,
    required this.chunksCompleted,
    required this.chunksVerified,
    required this.chunksFailed,
    required this.chunksRetransmitted,
    required this.speedBytesPerSecond,
    this.eta,
    required this.state,
    this.errorMessage,
    required this.updatedAt,
  });

  double get progressFraction => fileSize > 0 ? bytesTransferred / fileSize : 0.0;
  int get progressPercent => (progressFraction * 100).clamp(0, 100).toInt();

  Map<String, dynamic> toJson() => {
    'transfer_id': transferId,
    'filename': fileName,
    'file_size': fileSize,
    'bytes_transferred': bytesTransferred,
    'total_chunks': totalChunks,
    'chunks_completed': chunksCompleted,
    'chunks_verified': chunksVerified,
    'chunks_failed': chunksFailed,
    'chunks_retransmitted': chunksRetransmitted,
    'speed_bytes_per_second': speedBytesPerSecond,
    'eta_ms': eta?.inMilliseconds,
    'state': state.value,
    'error_message': errorMessage,
    'updated_at': updatedAt.toIso8601String(),
  };
}

class TransferInitRequest {
  final String fileId;
  final String fileName;
  final int fileSize;
  final String fileHash;
  final int chunkSize;
  final String? mimeType;
  final Map<String, dynamic>? metadata;

  TransferInitRequest({
    required this.fileId,
    required this.fileName,
    required this.fileSize,
    required this.fileHash,
    required this.chunkSize,
    this.mimeType,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'file_id': fileId,
    'filename': fileName,
    'file_size': fileSize,
    'file_hash': fileHash,
    'chunk_size': chunkSize,
    'mime_type': mimeType,
    'metadata': metadata,
  };
}

class TransferInitResponse {
  final String transferId;
  final int chunkSize;
  final int totalChunks;
  final List<int> missingChunks;

  TransferInitResponse({
    required this.transferId,
    required this.chunkSize,
    required this.totalChunks,
    required this.missingChunks,
  });

  factory TransferInitResponse.fromJson(Map<String, dynamic> json) => TransferInitResponse(
    transferId: json['transfer_id'] as String,
    chunkSize: json['chunk_size'] as int,
    totalChunks: json['total_chunks'] as int,
    missingChunks: (json['missing_chunks'] as List?)?.cast<int>() ?? [],
  );
}

class ChunkUploadRequest {
  final String transferId;
  final int chunkIndex;
  final int offset;
  final int length;
  final String hash;
  final List<int> data;

  ChunkUploadRequest({
    required this.transferId,
    required this.chunkIndex,
    required this.offset,
    required this.length,
    required this.hash,
    required this.data,
  });
}

class ChunkUploadResponse {
  final bool success;
  final String? error;
  final bool verified;

  ChunkUploadResponse({required this.success, this.error, this.verified = false});

  factory ChunkUploadResponse.fromJson(Map<String, dynamic> json) => ChunkUploadResponse(
    success: json['success'] as bool,
    error: json['error'] as String?,
    verified: json['verified'] as bool? ?? false,
  );
}

class TransferStatusResponse {
  final String transferId;
  final TransferState state;
  final int totalChunks;
  final List<int> receivedChunks;
  final List<int> missingChunks;
  final List<int> verifiedChunks;
  final String? fileHash;
  final String? error;

  TransferStatusResponse({
    required this.transferId,
    required this.state,
    required this.totalChunks,
    required this.receivedChunks,
    required this.missingChunks,
    required this.verifiedChunks,
    this.fileHash,
    this.error,
  });

  factory TransferStatusResponse.fromJson(Map<String, dynamic> json) => TransferStatusResponse(
    transferId: json['transfer_id'] as String,
    state: TransferState.fromString(json['state'] as String),
    totalChunks: json['total_chunks'] as int,
    receivedChunks: (json['received_chunks'] as List?)?.cast<int>() ?? [],
    missingChunks: (json['missing_chunks'] as List?)?.cast<int>() ?? [],
    verifiedChunks: (json['verified_chunks'] as List?)?.cast<int>() ?? [],
    fileHash: json['file_hash'] as String?,
    error: json['error'] as String?,
  );
}

class TransferVerifyRequest {
  final String transferId;
  final String expectedFileHash;

  TransferVerifyRequest({required this.transferId, required this.expectedFileHash});

  Map<String, dynamic> toJson() => {
    'transfer_id': transferId,
    'expected_file_hash': expectedFileHash,
  };
}

class TransferVerifyResponse {
  final bool success;
  final bool hashesMatch;
  final String? actualHash;
  final String? error;

  TransferVerifyResponse({
    required this.success,
    required this.hashesMatch,
    this.actualHash,
    this.error,
  });

  factory TransferVerifyResponse.fromJson(Map<String, dynamic> json) => TransferVerifyResponse(
    success: json['success'] as bool,
    hashesMatch: json['hashes_match'] as bool,
    actualHash: json['actual_hash'] as String?,
    error: json['error'] as String?,
  );
}

class TransferCompleteResponse {
  final bool success;
  final String? filePath;
  final String? error;

  TransferCompleteResponse({required this.success, this.filePath, this.error});

  factory TransferCompleteResponse.fromJson(Map<String, dynamic> json) => TransferCompleteResponse(
    success: json['success'] as bool,
    filePath: json['file_path'] as String?,
    error: json['error'] as String?,
  );
}

class ChunkSizeStrategy {
  static const int minChunkSize = 64 * 1024;
  static const int maxChunkSize = 64 * 1024 * 1024;
  static const int defaultChunkSize = 4 * 1024 * 1024;

  static int calculateChunkSize({
    required int fileSize,
    int? preferredSize,
    double? networkQuality,
  }) {
    int chunkSize = preferredSize ?? defaultChunkSize;

    if (fileSize <= 1024 * 1024) {
      chunkSize = fileSize;
    } else if (fileSize <= 10 * 1024 * 1024) {
      chunkSize = (chunkSize / 2).clamp(minChunkSize, maxChunkSize).toInt();
    } else if (fileSize <= 100 * 1024 * 1024) {
      chunkSize = chunkSize.clamp(minChunkSize, maxChunkSize).toInt();
    } else {
      chunkSize = (chunkSize * 2).clamp(minChunkSize, maxChunkSize).toInt();
    }

    if (networkQuality != null && networkQuality < 0.5) {
      chunkSize = (chunkSize / 2).clamp(minChunkSize, maxChunkSize).toInt();
    }

    return chunkSize.clamp(minChunkSize, maxChunkSize);
  }
}

extension TransferStateExt on TransferState {
  bool get isTerminal => this == TransferState.completed || this == TransferState.failed || this == TransferState.cancelled;
  bool get isActive => this == TransferState.preparing || this == TransferState.transferring || this == TransferState.verifying;
  bool get canResume => this == TransferState.paused || this == TransferState.interrupted || this == TransferState.retrying;
}