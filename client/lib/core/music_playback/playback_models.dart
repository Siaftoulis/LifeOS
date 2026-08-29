/// A single track in the playback queue.
class PlaybackItem {
  final String id;
  final String url;
  final String title;
  final String artist;
  final String thumbnail;
  final String album;
  final String filePath;

  const PlaybackItem({
    required this.id,
    required this.url,
    required this.title,
    required this.artist,
    this.thumbnail = '',
    this.album = '',
    this.filePath = '',
  });
}

/// Repeat semantics for the queue (generic — no just_audio types in the UI).
enum PlaybackRepeat { off, all, one }

/// Whether the queue currently auto-advances and what to do at the ends.
class PlaybackQueueState {
  final List<PlaybackItem> queue;
  final int currentIndex;
  final PlaybackRepeat repeat;
  final bool shuffle;

  const PlaybackQueueState({
    this.queue = const [],
    this.currentIndex = -1,
    this.repeat = PlaybackRepeat.off,
    this.shuffle = false,
  });

  PlaybackItem? get current =>
      (currentIndex >= 0 && currentIndex < queue.length)
          ? queue[currentIndex]
          : null;

  PlaybackQueueState copyWith({
    List<PlaybackItem>? queue,
    int? currentIndex,
    PlaybackRepeat? repeat,
    bool? shuffle,
  }) {
    return PlaybackQueueState(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      repeat: repeat ?? this.repeat,
      shuffle: shuffle ?? this.shuffle,
    );
  }
}