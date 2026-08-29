class MusicTrack {
  const MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.albumArtist = '',
    this.trackNumber,
    this.discNumber,
    this.year,
    this.genre = '',
    this.duration = 0,
    this.bitrate,
    this.codec = '',
    this.replayGainTrack,
    this.replayGainAlbum,
    this.playCount = 0,
    this.lastPlayedAt,
    this.addedAt,
    this.thumbnail = '',
    this.lyrics = '',
    this.thumbnailUrl = '',
    this.ytDlpId = '',
    this.filePath = '',
  });

  factory MusicTrack.fromJson(Map<String, dynamic> json) => MusicTrack(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Unknown',
        artist: json['artist']?.toString() ?? 'Unknown',
        album: json['album']?.toString() ?? '',
        albumArtist: json['album_artist']?.toString() ?? '',
        trackNumber: (json['track_number'] as num?)?.toInt(),
        discNumber: (json['disc_number'] as num?)?.toInt(),
        year: (json['year'] as num?)?.toInt(),
        genre: json['genre']?.toString() ?? '',
        duration: (json['duration'] as num?)?.toDouble() ?? 0,
        bitrate: (json['bitrate'] as num?)?.toInt(),
        codec: json['codec']?.toString() ?? '',
        replayGainTrack: (json['replay_gain_track'] as num?)?.toDouble(),
        replayGainAlbum: (json['replay_gain_album'] as num?)?.toDouble(),
        playCount: (json['play_count'] as num?)?.toInt() ?? 0,
        lastPlayedAt: (json['last_played_at'] as num?)?.toInt(),
        addedAt: (json['added_at'] as num?)?.toInt(),
        thumbnail: json['thumbnail']?.toString() ?? '',
        lyrics: json['lyrics']?.toString() ?? '',
        thumbnailUrl: json['thumbnail_url']?.toString() ?? '',
        ytDlpId: json['yt_dlp_id']?.toString() ?? '',
        filePath: json['file_path']?.toString() ?? '',
      );

  final String id;
  final String title;
  final String artist;
  final String album;
  final String albumArtist;
  final int? trackNumber;
  final int? discNumber;
  final int? year;
  final String genre;
  final double duration;
  final int? bitrate;
  final String codec;
  final double? replayGainTrack;
  final double? replayGainAlbum;
  final int playCount;
  final int? lastPlayedAt;
  final int? addedAt;
  final String thumbnail;
  final String lyrics;
  final String thumbnailUrl;
  final String ytDlpId;
  final String filePath;
}

class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    this.description = '',
    this.coverArtUrl = '',
    this.isSmart = false,
    this.smartType = '',
    this.smartConfig = '',
    this.trackCount = 0,
    this.totalDuration = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        coverArtUrl: json['cover_art_url']?.toString() ?? '',
        isSmart: json['is_smart'] == true,
        smartType: json['smart_type']?.toString() ?? '',
        smartConfig: json['smart_config']?.toString() ?? '',
        trackCount: (json['track_count'] as num?)?.toInt() ?? 0,
        totalDuration: (json['total_duration'] as num?)?.toInt() ?? 0,
        createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
        updatedAt: (json['updated_at'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String name;
  final String description;
  final String coverArtUrl;
  final bool isSmart;
  final String smartType;
  final String smartConfig;
  final int trackCount;
  final int totalDuration;
  final int createdAt;
  final int updatedAt;
}

class PlaylistCreate {
  final String name;
  final String description;
  final bool isSmart;
  final String smartType;
  final String smartConfig;

  PlaylistCreate({
    required this.name,
    this.description = '',
    this.isSmart = false,
    this.smartType = '',
    this.smartConfig = '',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'is_smart': isSmart,
    'smart_type': smartType,
    'smart_config': smartConfig,
  };
}

class PlaylistUpdate {
  final String name;
  final String description;
  final String coverArtUrl;

  PlaylistUpdate({this.name = '', this.description = '', this.coverArtUrl = ''});

  Map<String, dynamic> toJson() => {
    if (name.isNotEmpty) 'name': name,
    if (description.isNotEmpty) 'description': description,
    if (coverArtUrl.isNotEmpty) 'cover_art_url': coverArtUrl,
  };
}

class PlaylistTrack {
  const PlaylistTrack({
    required this.track,
    required this.position,
  });

  factory PlaylistTrack.fromJson(Map<String, dynamic> json) => PlaylistTrack(
        track: MusicTrack.fromJson(json['track'] ?? json),
        position: (json['position'] as num?)?.toInt() ?? 0,
      );

  final MusicTrack track;
  final int position;

  String get trackId => track.id;
}

class DownloadQueueItem {
  const DownloadQueueItem({
    required this.id,
    required this.trackId,
    required this.url,
    this.destinationPath = '',
    this.status = 'pending',
    this.priority = 0,
    this.retryCount = 0,
    this.totalBytes,
    this.downloadedBytes = 0,
    this.errorMessage = '',
    this.wifiOnly = true,
    this.chargingOnly = false,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  factory DownloadQueueItem.fromJson(Map<String, dynamic> json) => DownloadQueueItem(
        id: json['id']?.toString() ?? '',
        trackId: json['track_id']?.toString() ?? '',
        url: json['url']?.toString() ?? '',
        destinationPath: json['destination_path']?.toString() ?? '',
        status: json['status']?.toString() ?? 'pending',
        priority: (json['priority'] as num?)?.toInt() ?? 0,
        retryCount: (json['retry_count'] as num?)?.toInt() ?? 0,
        totalBytes: (json['total_bytes'] as num?)?.toInt(),
        downloadedBytes: (json['downloaded_bytes'] as num?)?.toInt() ?? 0,
        errorMessage: json['error_message']?.toString() ?? '',
        wifiOnly: json['wifi_only'] == true,
        chargingOnly: json['charging_only'] == true,
        createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
        startedAt: (json['started_at'] as num?)?.toInt(),
        completedAt: (json['completed_at'] as num?)?.toInt(),
      );

  final String id;
  final String trackId;
  final String url;
  final String destinationPath;
  final String status;
  final int priority;
  final int retryCount;
  final int? totalBytes;
  final int downloadedBytes;
  final String errorMessage;
  final bool wifiOnly;
  final bool chargingOnly;
  final int createdAt;
  final int? startedAt;
  final int? completedAt;

  String get title => trackId;
  String get artist => '';
  double? get progress => (totalBytes != null && totalBytes! > 0)
      ? (downloadedBytes / totalBytes!).clamp(0.0, 1.0)
      : null;
}

class DownloadQueueCreate {
  final String trackId;
  final String url;
  final int priority;
  final bool wifiOnly;
  final bool chargingOnly;

  DownloadQueueCreate({
    required this.trackId,
    required this.url,
    this.priority = 0,
    this.wifiOnly = true,
    this.chargingOnly = false,
  });

  Map<String, dynamic> toJson() => {
    'track_id': trackId,
    'url': url,
    'priority': priority,
    'wifi_only': wifiOnly,
    'charging_only': chargingOnly,
  };
}

class ListeningEvent {
  const ListeningEvent({
    required this.id,
    required this.trackId,
    required this.playedAt,
    this.positionMs = 0,
    this.durationMs,
    this.completionRate,
    this.skipped = false,
    this.source = '',
    this.title = '',
    this.artist = '',
    this.album = '',
    this.thumbnailUrl = '',
  });

  factory ListeningEvent.fromJson(Map<String, dynamic> json) => ListeningEvent(
        id: json['id']?.toString() ?? '',
        trackId: json['track_id']?.toString() ?? '',
        playedAt: (json['played_at'] as num?)?.toInt() ?? 0,
        positionMs: (json['position_ms'] as num?)?.toInt() ?? 0,
        durationMs: (json['duration_ms'] as num?)?.toInt(),
        completionRate: (json['completion_rate'] as num?)?.toDouble(),
        skipped: json['skipped'] == true,
        source: json['source']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        artist: json['artist']?.toString() ?? '',
        album: json['album']?.toString() ?? '',
        thumbnailUrl: json['thumbnail_url']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
    'track_id': trackId,
    'position_ms': positionMs,
    'duration_ms': durationMs,
    'completion_rate': completionRate,
    'skipped': skipped,
    'source': source,
  };

  final String id;
  final String trackId;
  final int playedAt;
  final int positionMs;
  final int? durationMs;
  final double? completionRate;
  final bool skipped;
  final String source;
  final String title;
  final String artist;
  final String album;
  final String thumbnailUrl;
}

class MusicStats {
  const MusicStats({
    required this.totalPlays,
    required this.uniqueTracks,
    required this.uniqueArtists,
    required this.totalMs,
    required this.topArtists,
    required this.topGenres,
  });

  factory MusicStats.fromJson(Map<String, dynamic> json) => MusicStats(
        totalPlays: (json['total_plays'] as num?)?.toInt() ?? 0,
        uniqueTracks: (json['unique_tracks'] as num?)?.toInt() ?? 0,
        uniqueArtists: (json['unique_artists'] as num?)?.toInt() ?? 0,
        totalMs: (json['total_ms'] as num?)?.toInt() ?? 0,
        topArtists: (json['top_artists'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        topGenres: (json['top_genres'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );

  factory MusicStats.empty() => const MusicStats(
        totalPlays: 0,
        uniqueTracks: 0,
        uniqueArtists: 0,
        totalMs: 0,
        topArtists: [],
        topGenres: [],
      );

  final int totalPlays;
  final int uniqueTracks;
  final int uniqueArtists;
  final int totalMs;
  final List<String> topArtists;
  final List<String> topGenres;
}
