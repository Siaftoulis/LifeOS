class YoutubeVideo {
  const YoutubeVideo({
    required this.id,
    required this.title,
    this.size = '',
    this.uploader = '',
    this.thumbnail = '',
    this.duration = 0,
    this.live = false,
  });

  factory YoutubeVideo.fromJson(Map<String, dynamic> json) => YoutubeVideo(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Untitled Video',
        size: json['size']?.toString() ?? '',
        uploader: json['uploader']?.toString() ?? '',
        thumbnail: json['thumbnail']?.toString() ?? '',
        duration: (json['duration'] as num?)?.toInt() ?? 0,
        live: json['live'] == true,
      );

  final String id;
  final String title;
  final String size;
  final String uploader;
  final String thumbnail;
  final int duration;
  final bool live;
}

class YoutubeStreamMeta {
  const YoutubeStreamMeta({
    required this.id,
    required this.live,
    this.title = '',
    this.hls = '',
    this.mp4 = '',
  });

  factory YoutubeStreamMeta.fromJson(Map<String, dynamic> json) => YoutubeStreamMeta(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        live: json['live'] == true,
        hls: json['hls']?.toString() ?? '',
        mp4: json['mp4']?.toString() ?? '',
      );

  final String id;
  final String title;
  final bool live;
  final String hls;
  final String mp4;
}

class YoutubeSession {
  const YoutubeSession({
    required this.active,
    this.startedAt = 0,
    this.elapsedMinutes = 0,
    this.estCost = 0,
  });

  factory YoutubeSession.fromJson(Map<String, dynamic> json) => YoutubeSession(
        active: json['active'] == true,
        startedAt: (json['started_at'] as num?)?.toInt() ?? 0,
        elapsedMinutes: (json['elapsed_minutes'] as num?)?.toInt() ?? 0,
        estCost: (json['est_cost'] as num?)?.toInt() ?? 0,
      );

  final bool active;
  final int startedAt;
  final int elapsedMinutes;
  final int estCost;

  DateTime? get started => startedAt > 0
      ? DateTime.fromMillisecondsSinceEpoch(startedAt * 1000)
      : null;
}

class SessionEnded {
  const SessionEnded({
    required this.status,
    this.elapsedMinutes = 0,
    this.pointsDeducted = 0,
    this.newBalance = 0,
  });

  factory SessionEnded.fromJson(Map<String, dynamic> json) => SessionEnded(
        status: json['status']?.toString() ?? '',
        elapsedMinutes: (json['elapsed_minutes'] as num?)?.toInt() ?? 0,
        pointsDeducted: (json['points_deducted'] as num?)?.toInt() ?? 0,
        newBalance: (json['new_balance'] as num?)?.toInt() ?? 0,
      );

  final String status;
  final int elapsedMinutes;
  final int pointsDeducted;
  final int newBalance;
}
