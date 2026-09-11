import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../theme/app_skin_manager.dart';
import '../../../../core/audio_dsp_service.dart';
import '../../../../core/domain_repositories.dart';
import '../../../../core/music_playback/playback_controller.dart';
import '../../../../core/music_playback/playback_models.dart';
import 'components/download_quality_dialog.dart';
import 'components/heart_button.dart';
import 'playlists/add_to_playlist_sheet.dart';
import 'waveform_seekbar.dart';
import 'track_metadata_modal.dart';
import 'lyrics_sync_viewer.dart';
import 'poweramp_equalizer_modal.dart';
import 'now_playing/now_playing_spectrogram.dart';
import 'music_formatters.dart';
import 'components/music_cover_art.dart';

enum NowPlayingCardMode {
  artwork,
  lyrics,
  visualizer,
}

/// Poweramp v3 Audiophile Studio Player
/// Provides an expansive full-width Desktop Studio layout and an adaptive Mobile view.
class PowerampNowPlayingSheet extends StatefulWidget {
  final AudioPlayer player;
  final String title;
  final String artist;
  final String album;
  final String trackId;
  final String streamUrl;
  final String thumbnailUrl;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;
  final VoidCallback? onOpenQueue;
  final VoidCallback? onDownloadOffline;
  final void Function(MusicTrack track)? onDownloadTrack;
  final void Function(MusicTrack track)? onDownloadOfflineTrack;
  final void Function(MusicTrack track)? onDeleteTrack;
  final bool isDownloaded;
  final bool isOfflineLocal;

  final List<PlaybackItem>? queue;
  final int currentIndex;
  final ValueChanged<int>? onPlayIndex;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final ValueChanged<int>? onRemove;
  final VoidCallback? onClearQueue;
  final PlaybackRepeat repeat;
  final bool shuffle;
  final ValueChanged<PlaybackRepeat>? onRepeatChanged;
  final ValueChanged<bool>? onShuffleChanged;

  const PowerampNowPlayingSheet({
    super.key,
    required this.player,
    required this.title,
    required this.artist,
    this.album = '',
    required this.trackId,
    required this.streamUrl,
    this.thumbnailUrl = '',
    required this.onNext,
    required this.onPrev,
    this.onDownload,
    this.onDelete,
    this.onOpenQueue,
    this.isDownloaded = false,
    this.onDownloadOffline,
    this.onDownloadTrack,
    this.onDownloadOfflineTrack,
    this.onDeleteTrack,
    this.isOfflineLocal = false,
    this.queue,
    this.currentIndex = -1,
    this.onPlayIndex,
    this.onReorder,
    this.onRemove,
    this.onClearQueue,
    this.repeat = PlaybackRepeat.off,
    this.shuffle = false,
    this.onRepeatChanged,
    this.onShuffleChanged,
  });

  static void show(
    BuildContext context, {
    required AudioPlayer player,
    required String title,
    required String artist,
    String album = '',
    required String trackId,
    required String streamUrl,
    String thumbnailUrl = '',
    required VoidCallback onNext,
    required VoidCallback onPrev,
    VoidCallback? onDownload,
    VoidCallback? onDelete,
    VoidCallback? onOpenQueue,
    bool isDownloaded = false,
    VoidCallback? onDownloadOffline,
    void Function(MusicTrack track)? onDownloadTrack,
    void Function(MusicTrack track)? onDownloadOfflineTrack,
    void Function(MusicTrack track)? onDeleteTrack,
    bool isOfflineLocal = false,
    List<PlaybackItem>? queue,
    int currentIndex = -1,
    ValueChanged<int>? onPlayIndex,
    void Function(int oldIndex, int newIndex)? onReorder,
    ValueChanged<int>? onRemove,
    VoidCallback? onClearQueue,
    PlaybackRepeat repeat = PlaybackRepeat.off,
    bool shuffle = false,
    ValueChanged<PlaybackRepeat>? onRepeatChanged,
    ValueChanged<bool>? onShuffleChanged,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width >= 820 ? 1040 : double.infinity),
      backgroundColor: Colors.transparent,
      builder: (_) => PowerampNowPlayingSheet(
        player: player,
        title: title,
        artist: artist,
        album: album,
        trackId: trackId,
        streamUrl: streamUrl,
        thumbnailUrl: thumbnailUrl,
        onNext: onNext,
        onPrev: onPrev,
        onDownload: onDownload,
        onDelete: onDelete,
        onOpenQueue: onOpenQueue,
        isDownloaded: isDownloaded,
        onDownloadOffline: onDownloadOffline,
        onDownloadTrack: onDownloadTrack,
        onDownloadOfflineTrack: onDownloadOfflineTrack,
        onDeleteTrack: onDeleteTrack,
        isOfflineLocal: isOfflineLocal,
        queue: queue,
        currentIndex: currentIndex,
        onPlayIndex: onPlayIndex,
        onReorder: onReorder,
        onRemove: onRemove,
        onClearQueue: onClearQueue,
        repeat: repeat,
        shuffle: shuffle,
        onRepeatChanged: onRepeatChanged,
        onShuffleChanged: onShuffleChanged,
      ),
    );
  }

  @override
  State<PowerampNowPlayingSheet> createState() => _PowerampNowPlayingSheetState();
}

class _PowerampNowPlayingSheetState extends State<PowerampNowPlayingSheet>
    with SingleTickerProviderStateMixin {
  NowPlayingCardMode _cardMode = NowPlayingCardMode.artwork;
  AudioVisualizerStyle _visualizerStyle = AudioVisualizerStyle.bars;
  int _desktopRightTab = 0; // 0 = Equalizer & DSP, 1 = Queue, 2 = Lyrics
  late bool _isShuffle;
  late PlaybackRepeat _repeat;
  late AnimationController _visualizerAnim;
  StreamSubscription<PlayerState>? _playerStateSub;

  String? _feedbackText;
  IconData? _feedbackIcon;
  Timer? _feedbackTimer;
  Timer? _longPressSeekTimer;
  late final FocusNode _focusNode;

  final List<double> _peakCaps = List.filled(32, 0.0);
  final List<double> _capVelocities = List.filled(32, 0.0);
  int _lastTickMicros = 0;
  final Stopwatch _visualizerStopwatch = Stopwatch();

  PlaybackItem? get _activeItem => PlaybackController.instance.currentItem;
  String get _activeTitle =>
      (_activeItem?.title.isNotEmpty == true) ? _activeItem!.title : widget.title;
  String get _activeArtist =>
      (_activeItem?.artist.isNotEmpty == true) ? _activeItem!.artist : widget.artist;
  String get _activeAlbum =>
      (_activeItem?.album.isNotEmpty == true) ? _activeItem!.album : widget.album;
  String get _activeThumbnail =>
      (_activeItem?.thumbnail.isNotEmpty == true)
          ? _activeItem!.thumbnail
          : widget.thumbnailUrl;
  String get _activeTrackId =>
      (_activeItem?.id.isNotEmpty == true) ? _activeItem!.id : widget.trackId;
  String get _activeStreamUrl =>
      (_activeItem?.url.isNotEmpty == true) ? _activeItem!.url : widget.streamUrl;

  bool get _isCurrentDownloaded =>
      MusicRepository.instance.tracks.value.any((t) => t.id == _activeTrackId);
  bool get _isCurrentOfflineLocal =>
      MusicRepository.instance.isOffline(_activeTrackId);

  MusicTrack get _currentTrack {
    final item = _activeItem;
    if (item != null) {
      return MusicTrack(
        id: item.id,
        title: item.title,
        artist: item.artist,
        album: item.album,
        thumbnail: item.thumbnail,
        duration: widget.player.duration?.inSeconds.toDouble() ?? 0,
      );
    }
    return MusicTrack(
      id: widget.trackId,
      title: widget.title,
      artist: widget.artist,
      album: widget.album,
      thumbnail: widget.thumbnailUrl,
      duration: widget.player.duration?.inSeconds.toDouble() ?? 0,
    );
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _isShuffle = PlaybackController.instance.isAvailable
        ? PlaybackController.instance.shuffle
        : widget.shuffle;
    _repeat = PlaybackController.instance.isAvailable
        ? PlaybackController.instance.repeat
        : widget.repeat;
    _visualizerAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3600),
    );
    _syncVisualizerWithPlayer(widget.player.playerState);
    _playerStateSub =
        widget.player.playerStateStream.listen(_syncVisualizerWithPlayer);
    PlaybackController.instance.addListener(_onPlaybackChanged);
    MusicRepository.instance.tracks.addListener(_onTracksChanged);
  }

  void _onPlaybackChanged() {
    if (!mounted) return;
    setState(() {
      _isShuffle = PlaybackController.instance.shuffle;
      _repeat = PlaybackController.instance.repeat;
    });
  }

  void _onTracksChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _syncVisualizerWithPlayer(PlayerState state) {
    final isPlaying =
        state.playing && state.processingState != ProcessingState.completed;
    if (isPlaying) {
      if (!_visualizerAnim.isAnimating) {
        _visualizerAnim.repeat();
      }
      if (!_visualizerStopwatch.isRunning) {
        _visualizerStopwatch.start();
      }
    } else {
      if (_visualizerAnim.isAnimating) {
        _visualizerAnim.stop();
      }
      _visualizerStopwatch.stop();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    PlaybackController.instance.removeListener(_onPlaybackChanged);
    MusicRepository.instance.tracks.removeListener(_onTracksChanged);
    _playerStateSub?.cancel();
    _visualizerAnim.dispose();
    _feedbackTimer?.cancel();
    _longPressSeekTimer?.cancel();
    super.dispose();
  }

  void _showFeedback(String text, IconData icon) {
    _feedbackTimer?.cancel();
    setState(() {
      _feedbackText = text;
      _feedbackIcon = icon;
    });
    _feedbackTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _feedbackText = null);
    });
  }

  void _seekRelative(Duration delta) {
    final cur = widget.player.position;
    final dur = widget.player.duration ?? Duration.zero;
    final target = Duration(
      milliseconds: (cur.inMilliseconds + delta.inMilliseconds).clamp(0, dur.inMilliseconds),
    );
    if (PlaybackController.instance.isAvailable) {
      PlaybackController.instance.seek(target);
    } else {
      widget.player.seek(target);
    }
    final sign = delta.inSeconds >= 0 ? '+' : '';
    final icon = delta.inSeconds >= 0 ? Icons.fast_forward_rounded : Icons.fast_rewind_rounded;
    _showFeedback('$sign${delta.inSeconds}s', icon);
  }

  void _togglePlayPause() {
    final playing = widget.player.playing;
    if (PlaybackController.instance.isAvailable) {
      PlaybackController.instance.togglePlayPause();
    } else {
      if (playing) {
        widget.player.pause();
      } else {
        widget.player.play();
      }
    }
    final willPlay = !playing;
    _showFeedback(
      willPlay ? 'Play' : 'Pause',
      willPlay ? Icons.play_arrow_rounded : Icons.pause_rounded,
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final focusedWidget = FocusManager.instance.primaryFocus?.context?.widget;
    if (focusedWidget is EditableText) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.space) {
      _togglePlayPause();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _seekRelative(const Duration(seconds: -5));
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _seekRelative(const Duration(seconds: 5));
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.mediaTrackNext) {
      widget.onNext();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.mediaTrackPrevious) {
      widget.onPrev();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.mediaPlayPause) {
      _togglePlayPause();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _buildFeedbackBadge(AppSkin skin) {
    if (_feedbackText == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: Center(
        child: IgnorePointer(
          child: AnimatedOpacity(
            opacity: _feedbackText != null ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white24, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_feedbackIcon != null) ...[
                    Icon(_feedbackIcon, color: skin.accent, size: 24),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    _feedbackText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startContinuousSeek(bool forward) {
    _longPressSeekTimer?.cancel();
    _longPressSeekTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _seekRelative(Duration(seconds: forward ? 2 : -2));
    });
  }

  void _stopContinuousSeek() {
    _longPressSeekTimer?.cancel();
  }

  void _cycleCardMode() {
    setState(() {
      switch (_cardMode) {
        case NowPlayingCardMode.artwork:
          _cardMode = NowPlayingCardMode.lyrics;
          break;
        case NowPlayingCardMode.lyrics:
          _cardMode = NowPlayingCardMode.visualizer;
          break;
        case NowPlayingCardMode.visualizer:
          _cardMode = NowPlayingCardMode.artwork;
          break;
      }
    });
  }

  @override
  void didUpdateWidget(covariant PowerampNowPlayingSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shuffle != widget.shuffle) {
      _isShuffle = widget.shuffle;
    }
    if (oldWidget.repeat != widget.repeat) {
      _repeat = widget.repeat;
    }
    if (oldWidget.player != widget.player) {
      _playerStateSub?.cancel();
      _syncVisualizerWithPlayer(widget.player.playerState);
      _playerStateSub =
          widget.player.playerStateStream.listen(_syncVisualizerWithPlayer);
    }
  }

  void _toggleLoopMode() {
    PlaybackRepeat nextMode;
    if (_repeat == PlaybackRepeat.off) {
      nextMode = PlaybackRepeat.all;
      _showFeedback('Repeat All', Icons.repeat_rounded);
    } else if (_repeat == PlaybackRepeat.all) {
      nextMode = PlaybackRepeat.one;
      _showFeedback('Repeat One', Icons.repeat_one_rounded);
    } else {
      nextMode = PlaybackRepeat.off;
      _showFeedback('Repeat Off', Icons.repeat_rounded);
    }
    if (PlaybackController.instance.isAvailable) {
      PlaybackController.instance.setRepeat(nextMode);
    }
    widget.onRepeatChanged?.call(nextMode);
    setState(() => _repeat = nextMode);
  }

  void _toggleShuffle() {
    final nextVal = !_isShuffle;
    _showFeedback(nextVal ? 'Shuffle On' : 'Shuffle Off', Icons.shuffle_rounded);
    if (PlaybackController.instance.isAvailable) {
      PlaybackController.instance.setShuffle(nextVal);
    }
    widget.onShuffleChanged?.call(nextVal);
    setState(() => _isShuffle = nextVal);
  }

  void _handleNext() {
    if (PlaybackController.instance.isAvailable) {
      PlaybackController.instance.next();
    } else {
      widget.onNext();
    }
  }

  void _handlePrev() {
    if (PlaybackController.instance.isAvailable) {
      PlaybackController.instance.previous();
    } else {
      widget.onPrev();
    }
  }

  Future<void> _handleDownload() async {
    final track = _currentTrack;
    final mode = await DownloadQualitySheet.show(context, track: track);
    if (mode == null || !mounted) return;
    if (mode == 'offline') {
      if (widget.onDownloadOfflineTrack != null) {
        widget.onDownloadOfflineTrack!(track);
      } else {
        widget.onDownloadOffline?.call();
      }
    } else {
      if (widget.onDownloadTrack != null) {
        widget.onDownloadTrack!(track);
      } else {
        widget.onDownload?.call();
      }
    }
  }

  void _handleDownloadOffline() {
    if (widget.onDownloadOfflineTrack != null) {
      widget.onDownloadOfflineTrack!(_currentTrack);
    } else {
      widget.onDownloadOffline?.call();
    }
  }

  void _handleDelete() {
    if (widget.onDeleteTrack != null) {
      widget.onDeleteTrack!(_currentTrack);
    } else {
      widget.onDelete?.call();
    }
  }

  void _openMetadataModal() {
    TrackMetadataModal.show(
      context,
      title: _activeTitle,
      artist: _activeArtist,
      album: _activeAlbum,
      trackId: _activeTrackId,
      url: _activeStreamUrl,
      duration: widget.player.duration ?? Duration.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 820;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        width: double.infinity,
        height: size.height * (isDesktop ? 0.95 : 0.94),
        decoration: BoxDecoration(
          color: skin.bg0,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: skin.isOled ? 0.95 : 0.75),
              blurRadius: 50,
              spreadRadius: 8,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Container(
            color: skin.bg0,
            child: SafeArea(
              top: false,
              child: Stack(
                children: [
                  isDesktop
                      ? _buildDesktopStudio(size, skin)
                      : _buildMobileLayout(size, skin),
                  _buildFeedbackBadge(skin),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // DESKTOP FULL-WIDTH STUDIO VIEW
  // ==========================================
  Widget _buildDesktopStudio(Size size, AppSkin skin) {
    final activeQueue = PlaybackController.instance.isAvailable &&
            PlaybackController.instance.queue.isNotEmpty
        ? PlaybackController.instance.queue
        : (widget.queue ?? []);

    return Column(
      children: [
        const SizedBox(height: 14),
        // Desktop Header Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.keyboard_arrow_down_rounded, color: skin.fg, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'BACK TO LIBRARY',
                        style: TextStyle(
                          color: skin.fg,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Audiophile Codec Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: skin.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'STREAMING · DSP ACTIVE',
                      style: TextStyle(
                        color: skin.fg,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_isCurrentDownloaded && (widget.onDelete != null || widget.onDeleteTrack != null))
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: skin.red, size: 22),
                  tooltip: 'Delete Song',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: skin.bg1,
                        title: Text('Delete Song', style: TextStyle(color: skin.fg)),
                        content: Text(
                          'Delete "$_activeTitle" from downloaded library?',
                          style: TextStyle(color: skin.textMuted),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('Cancel', style: TextStyle(color: skin.textMuted)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _handleDelete();
                            },
                            child: Text('Delete',
                                style: TextStyle(
                                    color: skin.red,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                )
              else if (!_isCurrentDownloaded && !_isCurrentOfflineLocal)
                IconButton(
                  icon: Icon(Icons.download_rounded, color: skin.accent, size: 22),
                  tooltip: 'Download Song',
                  onPressed: _handleDownload,
                ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.info_outline_rounded, color: skin.textMuted, size: 22),
                tooltip: 'Audio Specs',
                onPressed: _openMetadataModal,
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),
        const Divider(color: Colors.white10, height: 1),

        // Main Desktop Center Deck (Side-by-Side)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(36, 16, 36, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Panel: Hero Deck (Artwork / Spectrogram / Lyrics + Info)
                Expanded(
                  flex: 5,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final availableW = constraints.maxWidth - 24;
                      final availableH = constraints.maxHeight - 150;
                      final cardSize = math.min(availableW, availableH).clamp(160.0, 360.0);
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildHeroCard(cardSize: cardSize, skin: skin),
                          const SizedBox(height: 12),
                          _buildModeSelectorPills(skin: skin),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HeartButton(track: _currentTrack, size: 22),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _activeTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: skin.fg,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.4,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(Icons.playlist_add_rounded,
                                    color: skin.textMuted, size: 22),
                                tooltip: 'Add to Playlist',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => AddToPlaylistSheet.show(
                                    context, _currentTrack),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _activeArtist.isNotEmpty ? _activeArtist : 'Unknown Artist',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: skin.textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildMetadataBadgesRow(skin),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(width: 32),
                const VerticalDivider(color: Colors.white10, width: 1),
                const SizedBox(width: 32),

                // Right Panel: Studio Workstation (Equalizer, Queue Tabs)
                Expanded(
                  flex: 7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Segmented Tab Switcher (Only Equalizer, Queue, Lyrics)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: skin.bg1,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: [
                            _buildDesktopTabButton(0, Icons.equalizer_rounded, 'Equalizer & DSP', skin),
                            _buildDesktopTabButton(
                              1,
                              Icons.queue_music_rounded,
                              'Queue (${activeQueue.length})',
                              skin,
                            ),
                            _buildDesktopTabButton(2, Icons.lyrics_rounded, 'Lyrics', skin),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Active Tab Body
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: skin.bg1,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _buildDesktopRightTabContent(skin),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Master Transport & Waveform Dock
        Container(
          padding: const EdgeInsets.fromLTRB(36, 10, 36, 16),
          decoration: BoxDecoration(
            color: skin.bg1,
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildWaveformBar(skin),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Quick info & Shuffle/Repeat
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.shuffle_rounded,
                          color: _isShuffle ? skin.accent : skin.textMuted,
                          size: 22,
                        ),
                        tooltip: 'Shuffle',
                        onPressed: _toggleShuffle,
                      ),
                      IconButton(
                        icon: Icon(
                          _repeat == PlaybackRepeat.one
                              ? Icons.repeat_one_rounded
                              : Icons.repeat_rounded,
                          color: _repeat != PlaybackRepeat.off
                              ? skin.accent
                              : skin.textMuted,
                          size: 22,
                        ),
                        tooltip: 'Repeat',
                        onPressed: _toggleLoopMode,
                      ),
                    ],
                  ),

                  // Center: Main Transport (Rewind, Play/Pause, Fast-Forward)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onLongPressStart: (_) => _startContinuousSeek(false),
                        onLongPressEnd: (_) => _stopContinuousSeek(),
                        child: IconButton(
                          icon: Icon(Icons.skip_previous_rounded,
                              color: skin.fg, size: 36),
                          tooltip: 'Previous Track',
                          onPressed: _handlePrev,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildPlayPauseCircle(skin, size: 58),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onLongPressStart: (_) => _startContinuousSeek(true),
                        onLongPressEnd: (_) => _stopContinuousSeek(),
                        child: IconButton(
                          icon: Icon(Icons.skip_next_rounded,
                              color: skin.fg, size: 36),
                          tooltip: 'Next Track',
                          onPressed: _handleNext,
                        ),
                      ),
                    ],
                  ),

                  // Right: Volume & Cache Status
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isCurrentOfflineLocal
                              ? Icons.check_circle_rounded
                              : Icons.download_for_offline_rounded,
                          color: _isCurrentOfflineLocal
                              ? skin.accent
                              : skin.textMuted,
                          size: 22,
                        ),
                        tooltip: _isCurrentOfflineLocal
                            ? 'Saved on this device'
                            : 'Download for Offline',
                        onPressed: _handleDownloadOffline,
                      ),
                      const SizedBox(width: 8),
                      _buildDesktopVolumeSlider(skin),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTabButton(int index, IconData icon, String label, AppSkin skin) {
    final active = _desktopRightTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _desktopRightTab = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? skin.accent.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: active
                ? Border.all(color: skin.accent.withValues(alpha: 0.4))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: active ? skin.accent : skin.textMuted,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: active ? skin.accent : skin.textMuted,
                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopRightTabContent(AppSkin skin) {
    switch (_desktopRightTab) {
      case 0:
        return const PowerampEqualizerModal(isEmbedded: true);
      case 1:
        return _buildEmbeddedQueue(skin);
      case 2:
        return _buildDesktopLyricsWorkstation();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDesktopLyricsWorkstation() {
    return LyricsSyncViewer(
      key: ValueKey('desktop_lyrics_$_activeTrackId'),
      title: _activeTitle,
      artist: _activeArtist,
      player: widget.player,
      isEmbedded: true,
    );
  }

  String _formatDuration(double seconds) =>
      formatTrackDuration(seconds, allowEmpty: true);

  Widget _buildEmbeddedQueue(AppSkin skin) {
    final q = PlaybackController.instance.isAvailable &&
            PlaybackController.instance.queue.isNotEmpty
        ? PlaybackController.instance.queue
        : (widget.queue ?? []);
    final currentIdx = PlaybackController.instance.isAvailable &&
            PlaybackController.instance.currentIndex >= 0
        ? PlaybackController.instance.currentIndex
        : widget.currentIndex;

    if (q.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.queue_music_rounded,
                color: skin.textMuted, size: 40),
            const SizedBox(height: 8),
            Text(
              'Queue is empty',
              style: TextStyle(
                  color: skin.textMuted.withValues(alpha: 0.8),
                  fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'UP NEXT (${q.length})',
                style: TextStyle(
                  color: skin.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              TextButton(
                onPressed: () {
                  if (PlaybackController.instance.isAvailable) {
                    PlaybackController.instance.clearQueue();
                  } else {
                    widget.onClearQueue?.call();
                  }
                },
                child: Text('Clear',
                    style: TextStyle(color: skin.red, fontSize: 12)),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white10, height: 1),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: q.length,
            // ignore: deprecated_member_use
            onReorder: (oldIdx, newIdx) {
              if (PlaybackController.instance.isAvailable) {
                PlaybackController.instance.reorderQueue(oldIdx, newIdx);
              } else {
                widget.onReorder?.call(oldIdx, newIdx);
              }
            },
            itemBuilder: (context, i) {
              final item = q[i];
              final isCurrent = i == currentIdx;
              final meta =
                  MusicRepository.instance.getTrackMetadata(item.id);
              final thumbUrl = item.thumbnail.isNotEmpty
                  ? item.thumbnail
                  : (meta?.thumbnail ?? '');
              final durSec = meta?.duration ?? 0.0;
              final durText =
                  durSec > 0 ? _formatDuration(durSec) : '';

              return Material(
                key: ValueKey('queue_item_${item.id}_$i'),
                color: isCurrent
                    ? skin.accent.withValues(alpha: 0.14)
                    : Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    border: isCurrent
                        ? Border(
                            left: BorderSide(
                              color: skin.accent,
                              width: 3.5,
                            ),
                          )
                        : null,
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 2),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 24,
                          child: Center(
                            child: isCurrent
                                ? Icon(Icons.volume_up_rounded,
                                    color: skin.accent, size: 18)
                                : Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                        color: skin.textMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 38,
                            height: 38,
                            color: skin.bg0,
                            child: thumbUrl.isNotEmpty
                                ? Image.network(
                                    thumbUrl,
                                    width: 38,
                                    height: 38,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.music_note_rounded,
                                      color: skin.textMuted,
                                      size: 18,
                                    ),
                                  )
                                : Icon(
                                    Icons.music_note_rounded,
                                    color: skin.textMuted,
                                    size: 18,
                                  ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrent
                            ? skin.accent
                            : skin.fg,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      item.artist.isNotEmpty ? item.artist : 'LifeOS Library',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: skin.textMuted, fontSize: 11),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (durText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              durText,
                              style: TextStyle(
                                color: skin.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: skin.textMuted, size: 16),
                          tooltip: 'Remove from queue',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            if (PlaybackController.instance.isAvailable) {
                              PlaybackController.instance.removeAt(i);
                            } else {
                              widget.onRemove?.call(i);
                            }
                          },
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.drag_handle_rounded,
                            color: skin.textMuted, size: 18),
                      ],
                    ),
                    onTap: () {
                      if (PlaybackController.instance.isAvailable) {
                        PlaybackController.instance.playAt(i);
                      } else {
                        widget.onPlayIndex?.call(i);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopVolumeSlider(AppSkin skin) {
    return StreamBuilder<double>(
      stream: widget.player.volumeStream,
      builder: (context, snap) {
        final vol = snap.data ?? widget.player.volume;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                vol == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: skin.textMuted,
                size: 20,
              ),
              onPressed: () => widget.player.setVolume(vol > 0 ? 0.0 : 1.0),
            ),
            SizedBox(
              width: 100,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                  activeTrackColor: skin.accent,
                  inactiveTrackColor: Colors.white12,
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  value: vol,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (v) => widget.player.setVolume(v),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // MOBILE ADAPTIVE VIEW (Zero-Overflow)
  // ==========================================
  Widget _buildMobileLayout(Size size, AppSkin skin) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Drag Handle with Fling Down Dismiss
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! > 150) {
                Navigator.pop(context);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 48),
              child: Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: skin.textMuted.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                      color: skin.fg, size: 28),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Dismiss',
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: skin.bg1,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: skin.bg2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: skin.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'POWERAMP DSP',
                        style: TextStyle(
                          color: skin.fg,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isCurrentDownloaded && (widget.onDelete != null || widget.onDeleteTrack != null))
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded,
                            color: skin.red, size: 22),
                        tooltip: 'Delete Song',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: skin.bg1,
                              title: Text('Delete Song',
                                  style: TextStyle(color: skin.fg)),
                              content: Text(
                                'Delete "$_activeTitle" from downloaded library?',
                                style: TextStyle(color: skin.textMuted),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text('Cancel',
                                      style: TextStyle(color: skin.textMuted)),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _handleDelete();
                                  },
                                  child: Text('Delete',
                                      style: TextStyle(
                                          color: skin.red,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    else if (!_isCurrentDownloaded && !_isCurrentOfflineLocal)
                      IconButton(
                        icon: Icon(Icons.download_rounded,
                            color: skin.accent, size: 22),
                        tooltip: 'Download Song',
                        onPressed: _handleDownload,
                      ),
                    IconButton(
                      icon: Icon(Icons.info_outline_rounded,
                          color: skin.textMuted, size: 22),
                      tooltip: 'Audio Specs',
                      onPressed: _openMetadataModal,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Center Hero Area (Adaptive, zero overflow, scales dynamically)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxSide = math.min(constraints.maxWidth, constraints.maxHeight);
                    final clampedSide = maxSide.clamp(130.0, 275.0);
                    return _buildHeroCard(cardSize: clampedSide, skin: skin);
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),
          _buildModeSelectorPills(skin: skin),

          const SizedBox(height: 8),
          _buildTrackInfo(skin: skin),

          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildWaveformBar(skin),
          ),

          const SizedBox(height: 6),
          _buildMobileTransport(skin),

          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildMobileDock(skin),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard({required double cardSize, required AppSkin skin}) {
    final isLyricsMode = _cardMode == NowPlayingCardMode.lyrics;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (isLyricsMode) {
              setState(() => _cardMode = NowPlayingCardMode.artwork);
            } else {
              _cycleCardMode();
            }
          },
          onLongPress: isLyricsMode ? null : _openMetadataModal,
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity! > 200) {
              Navigator.of(context).pop();
            }
          },
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! < -200) {
                _handleNext();
                _showFeedback('Next Track', Icons.skip_next_rounded);
              } else if (details.primaryVelocity! > 200) {
                _handlePrev();
                _showFeedback('Previous Track', Icons.skip_previous_rounded);
              }
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.96, end: 1.0).animate(anim),
                    child: child,
                  ),
                ),
                child: _buildCenterCardContent(cardSize, skin),
              ),

              // HUD Feedback
              if (_feedbackText != null)
                Positioned(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: skin.accent.withValues(alpha: 0.5)),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 15),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_feedbackIcon != null) ...[
                          Icon(_feedbackIcon, color: skin.accent, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _feedbackText!,
                          style: TextStyle(
                            color: skin.fg,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCenterCardContent(double cardSize, AppSkin skin) {
    switch (_cardMode) {
      case NowPlayingCardMode.artwork:
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: SizedBox(
            key: ValueKey('artwork_${_activeTrackId}_$_activeThumbnail'),
            width: cardSize,
            height: cardSize,
            child: AspectRatio(
              aspectRatio: 1.0,
              child: MusicCoverArt(
                url: _activeThumbnail,
                size: cardSize,
                borderRadius: 22,
                fallback: _buildFallbackArt(skin),
              ),
            ),
          ),
        );

      case NowPlayingCardMode.lyrics:
        return Container(
          key: ValueKey('lyrics_card_${_activeTrackId}'),
          width: cardSize,
          height: cardSize,
          decoration: BoxDecoration(
            color: skin.bg1,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(top: 36, left: 10, right: 10, bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: LyricsSyncViewer(
                      key: ValueKey('lyrics_viewer_${_activeTrackId}'),
                      title: _activeTitle,
                      artist: _activeArtist,
                      player: widget.player,
                      isEmbedded: true,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _cardMode = NowPlayingCardMode.artwork),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.album_rounded, size: 14, color: skin.accent),
                            const SizedBox(width: 5),
                            Text('Artwork',
                                style: TextStyle(
                                    color: skin.fg,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _cardMode = NowPlayingCardMode.visualizer),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.graphic_eq_rounded, size: 14, color: skin.yellow),
                            const SizedBox(width: 5),
                            Text('Spectrum',
                                style: TextStyle(
                                    color: skin.fg,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case NowPlayingCardMode.visualizer:
        return Container(
          key: ValueKey('visualizer_card_${_activeTrackId}'),
          width: cardSize,
          height: cardSize,
          decoration: BoxDecoration(
            color: skin.bg1,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: StreamBuilder<Duration>(
                  stream: widget.player.positionStream,
                  builder: (context, posSnap) {
                    final pos = posSnap.data ?? Duration.zero;
                    return StreamBuilder<PlayerState>(
                      stream: widget.player.playerStateStream,
                      builder: (context, stateSnap) {
                        final playing = stateSnap.data?.playing ?? false;
                        return AnimatedBuilder(
                          animation: _visualizerAnim,
                          builder: (context, _) {
                            final nowMicros = DateTime.now().microsecondsSinceEpoch;
                            final dt = _lastTickMicros == 0
                                ? 0.016
                                : ((nowMicros - _lastTickMicros) / 1000000.0).clamp(0.001, 0.05);
                            _lastTickMicros = nowMicros;
                            final continuousMs = pos.inMilliseconds.toDouble() +
                                (playing ? (_visualizerStopwatch.elapsedMilliseconds % 1000) : 0.0);
                            return CustomPaint(
                              painter: AudioReactiveSpectrogramPainter(
                                position: pos,
                                trackId: _activeTrackId,
                                playing: playing,
                                peakCaps: _peakCaps,
                                capVelocities: _capVelocities,
                                dspGains: AudioDspService.instance.bands,
                                bassBoost: AudioDspService.instance.bassBoost,
                                style: _visualizerStyle,
                                skin: skin,
                                animTimeMs: continuousMs,
                                dt: dt,
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                    decoration: BoxDecoration(
                      color: skin.bg0.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildVisualizerStylePill('BARS', AudioVisualizerStyle.bars, skin),
                        const SizedBox(width: 4),
                        _buildVisualizerStylePill('BEAM', AudioVisualizerStyle.beam, skin),
                        const SizedBox(width: 4),
                        _buildVisualizerStylePill('HALO', AudioVisualizerStyle.halo, skin),
                        const SizedBox(width: 4),
                        _buildVisualizerStylePill('VU', AudioVisualizerStyle.vu, skin),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildVisualizerStylePill(String label, AudioVisualizerStyle style, AppSkin skin) {
    final active = _visualizerStyle == style;
    return GestureDetector(
      onTap: () => setState(() => _visualizerStyle = style),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? skin.accent.withValues(alpha: 0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? skin.accent : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? skin.accent : skin.textMuted,
            fontSize: 9.0,
            fontWeight: active ? FontWeight.bold : FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelectorPills({required AppSkin skin}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: skin.bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: skin.bg2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeChip('ARTWORK', Icons.album_rounded, NowPlayingCardMode.artwork, skin),
          const SizedBox(width: 4),
          _buildModeChip('LYRICS', Icons.lyrics_rounded, NowPlayingCardMode.lyrics, skin),
          const SizedBox(width: 4),
          _buildModeChip('SPECTRUM', Icons.graphic_eq_rounded, NowPlayingCardMode.visualizer, skin),
          const SizedBox(width: 4),
          _buildRadioChip(skin),
        ],
      ),
    );
  }

  Widget _buildRadioChip(AppSkin skin) {
    final pc = PlaybackController.instance;
    final active = pc.infiniteRadio;
    final lookahead = pc.lookaheadWindow;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          pc.toggleInfiniteRadio();
          setState(() {});
          _showFeedback(
            pc.infiniteRadio
                ? 'Infinite Radio: ON (${pc.lookaheadWindow}x Pre-cache)'
                : 'Infinite Radio: OFF',
            Icons.sensors_rounded,
          );
        },
        onLongPress: () => _showLookaheadSelector(skin),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active
                ? skin.accent.withValues(alpha: skin.isOled ? 0.25 : 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? skin.accent.withValues(alpha: 0.7) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sensors_rounded,
                size: 13,
                color: active ? skin.accent : skin.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                active ? 'RADIO (${lookahead}x)' : 'RADIO',
                style: TextStyle(
                  color: active ? skin.accent : skin.textMuted,
                  fontSize: 10,
                  fontWeight: active ? FontWeight.bold : FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLookaheadSelector(AppSkin skin) {
    final pc = PlaybackController.instance;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: BoxDecoration(
              color: skin.bg0,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.fast_forward_rounded, color: skin.accent, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Lookahead Pre-caching Depth',
                      style: TextStyle(
                        color: skin.fg,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Select how many songs ahead should be pre-buffered in the background to ensure zero-lag instant transitions.',
                  style: TextStyle(color: skin.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 18),
                ...[2, 3, 4].map((count) {
                  final isSel = pc.lookaheadWindow == count;
                  final label = count == 2
                      ? '2 Songs (Standard - 0s lag on normal play)'
                      : count == 3
                          ? '3 Songs (Recommended - Balanced instant buffering)'
                          : '4 Songs (Deep Buffer - Instant even on rapid skips)';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        pc.setLookaheadWindow(count);
                        pc.precacheUpcoming();
                        setModalState(() {});
                        setState(() {});
                        Navigator.pop(ctx);
                        _showFeedback(
                          'Pre-cache lookahead set to $count songs ahead',
                          Icons.speed_rounded,
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSel
                              ? skin.accent.withValues(alpha: 0.15)
                              : skin.bg1,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSel ? skin.accent : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSel
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: isSel ? skin.accent : skin.textMuted,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: isSel ? skin.fg : skin.textMuted,
                                  fontWeight:
                                      isSel ? FontWeight.w600 : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModeChip(String label, IconData icon, NowPlayingCardMode mode, AppSkin skin) {
    final active = _cardMode == mode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _cardMode = mode),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active
                ? skin.accent.withValues(alpha: skin.isOled ? 0.25 : 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? skin.accent.withValues(alpha: 0.7) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: active ? skin.accent : skin.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: active ? skin.accent : skin.textMuted,
                  fontSize: 10,
                  fontWeight: active ? FontWeight.bold : FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackInfo({required AppSkin skin}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          HeartButton(track: _currentTrack, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    _activeTitle,
                    key: ValueKey('title_${_activeTrackId}_$_activeTitle'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: skin.fg,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    _activeArtist.isNotEmpty ? _activeArtist : 'Unknown Artist',
                    key: ValueKey('artist_${_activeTrackId}_$_activeArtist'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: skin.textMuted,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_activeAlbum.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _activeAlbum,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: skin.textMuted.withValues(alpha: 0.65),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                _buildMetadataBadgesRow(skin),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(Icons.playlist_add_rounded,
                color: skin.textMuted, size: 24),
            tooltip: 'Add to Playlist',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () =>
                AddToPlaylistSheet.show(context, _currentTrack),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataBadgesRow(AppSkin skin) {
    final item = _activeItem;
    final streamType = PlaybackController.instance.activeStreamType;
    final isLocal = _isCurrentOfflineLocal || _isCurrentDownloaded;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        // Source Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: skin.accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: skin.accent.withValues(alpha: 0.3)),
          ),
          child: Text(
            isLocal ? 'LOCAL VAULT' : 'YTM ONLINE',
            style: TextStyle(
              color: skin.accent,
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
        ),

        // Quality / Codec Badge
        if (streamType.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              streamType,
              style: TextStyle(
                color: skin.fg.withValues(alpha: 0.85),
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),

        // Album Badge
        if (_activeAlbum.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.album_rounded, size: 10, color: skin.textMuted),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    _activeAlbum,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: skin.textMuted,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Genre Badge
        if (item != null && item.genre.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              item.genre,
              style: TextStyle(
                color: skin.textMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // Year Badge
        if (item != null && item.year > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              '${item.year}',
              style: TextStyle(
                color: skin.textMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }



  Widget _buildWaveformBar(AppSkin skin) {
    return StreamBuilder<Duration>(
      stream: widget.player.positionStream,
      builder: (context, posSnap) {
        final pos = posSnap.data ?? Duration.zero;
        return StreamBuilder<Duration?>(
          stream: widget.player.durationStream,
          builder: (context, durSnap) {
            final dur = durSnap.data ?? Duration.zero;
            return WaveformSeekbar(
              position: pos,
              duration: dur,
              trackId: _activeTrackId,
              audioUrl: _activeStreamUrl,
              height: 42,
              activeColor: skin.accent,
              inactiveColor: Colors.white.withValues(alpha: 0.15),
              onSeek: (target) => widget.player.seek(target),
            );
          },
        );
      },
    );
  }

  Widget _buildPlayPauseCircle(AppSkin skin, {double size = 62}) {
    return StreamBuilder<PlayerState>(
      stream: widget.player.playerStateStream,
      builder: (context, snap) {
        final state = snap.data;
        final playing = state?.playing ?? false;
        final loading = state?.processingState == ProcessingState.loading;
        final iconColor = skin.isOled
            ? Colors.black
            : (skin.isDark ? Colors.black : Colors.white);

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: skin.accent,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(size / 2),
              onTap: loading
                  ? null
                  : () {
                      if (PlaybackController.instance.isAvailable) {
                        PlaybackController.instance.togglePlayPause();
                      } else {
                        if (playing) {
                          widget.player.pause();
                        } else {
                          widget.player.play();
                        }
                      }
                    },
              child: Center(
                child: loading
                    ? SizedBox(
                        width: size * 0.42,
                        height: size * 0.42,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: iconColor,
                        ),
                      )
                    : Icon(
                        playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: iconColor,
                        size: size * 0.62,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileTransport(AppSkin skin) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            iconSize: 24,
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Icon(
              Icons.shuffle_rounded,
              color: _isShuffle ? skin.accent : skin.textMuted,
            ),
            tooltip: 'Shuffle',
            onPressed: _toggleShuffle,
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPressStart: (_) => _startContinuousSeek(false),
            onLongPressEnd: (_) => _stopContinuousSeek(),
            child: IconButton(
              iconSize: 38,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: Icon(Icons.skip_previous_rounded,
                  color: skin.fg),
              tooltip: 'Previous Track',
              onPressed: _handlePrev,
            ),
          ),
          _buildPlayPauseCircle(skin, size: 62),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPressStart: (_) => _startContinuousSeek(true),
            onLongPressEnd: (_) => _stopContinuousSeek(),
            child: IconButton(
              iconSize: 38,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: Icon(Icons.skip_next_rounded,
                  color: skin.fg),
              tooltip: 'Next Track',
              onPressed: _handleNext,
            ),
          ),
          IconButton(
            iconSize: 24,
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Icon(
              _repeat == PlaybackRepeat.one
                  ? Icons.repeat_one_rounded
                  : Icons.repeat_rounded,
              color: _repeat != PlaybackRepeat.off
                  ? skin.accent
                  : skin.textMuted,
            ),
            tooltip: 'Repeat Mode',
            onPressed: _toggleLoopMode,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDock(AppSkin skin) {
    final isOffline = _isCurrentOfflineLocal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: skin.bg1,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: skin.bg2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildDockButton(
              skin: skin,
              icon: Icons.lyrics_rounded,
              label: 'Lyrics',
              active: _cardMode == NowPlayingCardMode.lyrics,
              onTap: () {
                setState(() {
                  _cardMode = _cardMode == NowPlayingCardMode.lyrics
                      ? NowPlayingCardMode.artwork
                      : NowPlayingCardMode.lyrics;
                });
              },
            ),
          ),
          Expanded(
            child: _buildDockButton(
              skin: skin,
              icon: Icons.graphic_eq_rounded,
              label: 'Spectrum',
              active: _cardMode == NowPlayingCardMode.visualizer,
              onTap: () {
                setState(() {
                  _cardMode = _cardMode == NowPlayingCardMode.visualizer
                      ? NowPlayingCardMode.artwork
                      : NowPlayingCardMode.visualizer;
                });
              },
            ),
          ),
          Expanded(
            child: _buildDockButton(
              skin: skin,
              icon: Icons.equalizer_rounded,
              label: 'Equalizer',
              active: false,
              onTap: () => PowerampEqualizerModal.show(context),
            ),
          ),
          Expanded(
            child: _buildDockButton(
              skin: skin,
              icon: Icons.queue_music_rounded,
              label: 'Queue',
              active: false,
              onTap: widget.onOpenQueue,
            ),
          ),
          Expanded(
            child: _buildDockButton(
              skin: skin,
              icon: isOffline
                  ? Icons.check_circle_rounded
                  : Icons.download_for_offline_rounded,
              label: isOffline ? 'On Device' : 'Download',
              active: isOffline,
              onTap: _handleDownloadOffline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackArt(AppSkin skin) {
    return Container(
      color: skin.bg1,
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: skin.accent.withValues(alpha: 0.8),
          size: 70,
        ),
      ),
    );
  }

  Widget _buildDockButton({
    required AppSkin skin,
    required IconData icon,
    required String label,
    required bool active,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: active ? skin.accent : skin.textMuted,
                size: 20,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? skin.accent : skin.textMuted,
                  fontSize: 10,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


