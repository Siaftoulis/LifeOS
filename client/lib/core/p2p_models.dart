class P2PProgress {
  final String fileName;
  final int bytesTransferred;
  final int totalBytes;
  final bool isSender;
  final double speedMBs;
  final bool isCompleted;

  P2PProgress({
    required this.fileName,
    required this.bytesTransferred,
    required this.totalBytes,
    required this.isSender,
    required this.speedMBs,
    required this.isCompleted,
  });

  double get percent => totalBytes > 0 ? bytesTransferred / totalBytes : 0.0;
}

class RemoteCursor {
  final String userId;
  final double x;
  final double y;
  final String filePath;
  final DateTime timestamp;

  RemoteCursor({
    required this.userId,
    required this.x,
    required this.y,
    required this.filePath,
    required this.timestamp,
  });
}
