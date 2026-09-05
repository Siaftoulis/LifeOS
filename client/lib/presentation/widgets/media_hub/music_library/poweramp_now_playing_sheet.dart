import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../theme/everforest_colors.dart';
import '../../../../core/audio_dsp_service.dart';
import '../../../../core/domain_repositories.dart';
import '../../../../core/music_playback/playback_models.dart';
import 'components/heart_button.dart';
import 'playlists/add_to_playlist_sheet.dart';
import 'waveform_seekbar.dart';
import 'track_metadata_modal.dart';
import 'lyrics_sync_viewer.dart';
import 'poweramp_equalizer_modal.dart';
import 'now_playing/now_playing_spectrogram.dart';

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
      constraints: const BoxConstraints(maxWidth: double.infinity),
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
  int _desktopRightTab = 0; // 0 = Equalizer & DSP, 1 = Queue
  late bool _isShuffle;
  late PlaybackRepeat _repeat;
  late AnimationController _visualizerAnim;

  String? _feedbackText;
  IconData? _feedbackIcon;
  Timer? _feedbackTimer;
  Timer? _longPressSeekTimer;

  final List<double> _peakCaps = List.filled(32, 0.0);
  final List<double> _capVelocities = List.filled(32, 0.0);

  @override
  void initState() {
    super.initState();
    _isShuffle = widget.shuffle;
    _repeat = widget.repeat;
    _visualizerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
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
    widget.player.seek(target);
    final sign = delta.inSeconds >= 0 ? '+' : '';
    final icon = delta.inSeconds >= 0 ? Icons.fast_forward_rounded : Icons.fast_rewind_rounded;
    _showFeedback('$sign${delta.inSeconds}s', icon);
  }

  void _adjustVolume(double delta) {
    final cur = widget.player.volume;
    final next = (cur + delta).clamp(0.0, 1.0);
    widget.player.setVolume(next);
    final pct = (next * 100).round();
    final icon = next == 0
        ? Icons.volume_off_rounded
        : (next < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded);
    _showFeedback('Vol $pct%', icon);
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
  }

  void _toggleLoopMode() {
    setState(() {
      if (_repeat == PlaybackRepeat.off) {
        _repeat = PlaybackRepeat.all;
        _showFeedback('Repeat All', Icons.repeat_rounded);
      } else if (_repeat == PlaybackRepeat.all) {
        _repeat = PlaybackRepeat.one;
        _showFeedback('Repeat One', Icons.repeat_one_rounded);
      } else {
        _repeat = PlaybackRepeat.off;
        _showFeedback('Repeat Off', Icons.repeat_rounded);
      }
      widget.onRepeatChanged?.call(_repeat);
    });
  }

  void _toggleShuffle() {
    setState(() {
      _isShuffle = !_isShuffle;
      _showFeedback(_isShuffle ? 'Shuffle On' : 'Shuffle Off', Icons.shuffle_rounded);
      widget.onShuffleChanged?.call(_isShuffle);
    });
  }

  MusicTrack get _currentTrack => MusicTrack(
        id: widget.trackId,
        title: widget.title,
        artist: widget.artist,
        album: widget.album,
        thumbnail: widget.thumbnailUrl,
        duration: widget.player.duration?.inSeconds.toDouble() ?? 0,
      );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 820;

    return Container(
      width: double.infinity,
      height: size.height * (isDesktop ? 0.95 : 0.94),
      decoration: BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 50,
            spreadRadius: 8,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Stack(
          children: [
            // Ambient Backdrop Glow
            Positioned.fill(
              child: Stack(
                children: [
                  Positioned(
                    top: -120,
                    left: 0,
                    right: 0,
                    height: 500,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topCenter,
                          radius: 1.4,
                          colors: [
                            EverforestColors.green.withValues(alpha: 0.22),
                            EverforestColors.aqua.withValues(alpha: 0.12),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                    child: Container(color: Colors.transparent),
                  ),
                ],
              ),
            ),

            // Content Body
            SafeArea(
              top: false,
              child: isDesktop ? _buildDesktopStudio(size) : _buildMobileLayout(size),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // DESKTOP FULL-WIDTH STUDIO VIEW
  // ==========================================
  Widget _buildDesktopStudio(Size size) {
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
                  child: const Row(
                    children: [
                      Icon(Icons.keyboard_arrow_down_rounded, color: EverforestColors.fg, size: 20),
                      SizedBox(width: 6),
                      Text(
                        'BACK TO LIBRARY',
                        style: TextStyle(
                          color: EverforestColors.fg,
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
                      decoration: const BoxDecoration(
                        color: EverforestColors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'STREAMING · DSP ACTIVE',
                      style: TextStyle(
                        color: EverforestColors.fg,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (widget.isDownloaded && widget.onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: EverforestColors.red, size: 22),
                  tooltip: 'Delete Song',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: EverforestColors.bg1,
                        title: const Text('Delete Song', style: TextStyle(color: EverforestColors.fg)),
                        content: Text(
                          'Delete "${widget.title}" from downloaded library?',
                          style: const TextStyle(color: EverforestColors.grey),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel', style: TextStyle(color: EverforestColors.grey)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.pop(context);
                              widget.onDelete?.call();
                            },
                            child: const Text('Delete', style: TextStyle(color: EverforestColors.red, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                )
              else if (!widget.isDownloaded && widget.onDownload != null)
                IconButton(
                  icon: const Icon(Icons.download_rounded, color: EverforestColors.green, size: 22),
                  tooltip: 'Download Song',
                  onPressed: widget.onDownload,
                ),
              if (!widget.isOfflineLocal && widget.onDownloadOffline != null)
                IconButton(
                  icon: const Icon(Icons.download_for_offline_rounded, color: EverforestColors.aqua, size: 22),
                  tooltip: 'Save to this device (offline)',
                  onPressed: widget.onDownloadOffline,
                ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, color: EverforestColors.grey, size: 22),
                tooltip: 'Audio Specs',
                onPressed: () => TrackMetadataModal.show(
                  context,
                  title: widget.title,
                  artist: widget.artist,
                  album: widget.album,
                  trackId: widget.trackId,
                  url: widget.streamUrl,
                  duration: widget.player.duration ?? Duration.zero,
                ),
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
                      final cardSize = (constraints.maxHeight - 105).clamp(150.0, 360.0);
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildHeroCard(cardSize: cardSize),
                          const SizedBox(height: 12),
                          _buildModeSelectorPills(),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              HeartButton(track: _currentTrack, size: 22),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  widget.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: EverforestColors.fg,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.playlist_add_rounded,
                                    color: EverforestColors.grey, size: 22),
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
                            widget.artist.isNotEmpty ? widget.artist : 'Unknown Artist',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: EverforestColors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
                      // Segmented Tab Switcher (Only Equalizer & Queue)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: EverforestColors.bg1,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: [
                            _buildDesktopTabButton(0, Icons.equalizer_rounded, 'Equalizer & DSP'),
                            _buildDesktopTabButton(
                              1,
                              Icons.queue_music_rounded,
                              'Queue (${widget.queue?.length ?? 0})',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Active Tab Body
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: EverforestColors.bg1,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _buildDesktopRightTabContent(),
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
            color: EverforestColors.bg1,
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildWaveformBar(),
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
                          color: _isShuffle ? EverforestColors.green : EverforestColors.grey,
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
                              ? EverforestColors.green
                              : EverforestColors.grey,
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
                          icon: const Icon(Icons.skip_previous_rounded,
                              color: EverforestColors.fg, size: 36),
                          onPressed: widget.onPrev,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildPlayPauseCircle(size: 58),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onLongPressStart: (_) => _startContinuousSeek(true),
                        onLongPressEnd: (_) => _stopContinuousSeek(),
                        child: IconButton(
                          icon: const Icon(Icons.skip_next_rounded,
                              color: EverforestColors.fg, size: 36),
                          onPressed: widget.onNext,
                        ),
                      ),
                    ],
                  ),

                  // Right: Volume & Cache Status
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          widget.isOfflineLocal
                              ? Icons.check_circle_rounded
                              : Icons.download_for_offline_rounded,
                          color: widget.isOfflineLocal
                              ? EverforestColors.green
                              : EverforestColors.grey,
                          size: 22,
                        ),
                        tooltip: widget.isOfflineLocal
                            ? 'Saved on this device'
                            : 'Download for Offline',
                        onPressed: widget.onDownloadOffline,
                      ),
                      const SizedBox(width: 8),
                      _buildDesktopVolumeSlider(),
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

  Widget _buildDesktopTabButton(int index, IconData icon, String label) {
    final active = _desktopRightTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _desktopRightTab = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? EverforestColors.green.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: active
                ? Border.all(color: EverforestColors.green.withValues(alpha: 0.4))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: active ? EverforestColors.green : EverforestColors.grey,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: active ? EverforestColors.green : EverforestColors.grey,
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

  Widget _buildDesktopRightTabContent() {
    switch (_desktopRightTab) {
      case 0:
        return const PowerampEqualizerModal(isEmbedded: true);
      case 1:
        return _buildEmbeddedQueue();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEmbeddedQueue() {
    final q = widget.queue ?? [];
    if (q.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.queue_music_rounded, color: EverforestColors.grey, size: 40),
            const SizedBox(height: 8),
            Text(
              'Queue is empty',
              style: TextStyle(color: EverforestColors.grey.withValues(alpha: 0.8), fontSize: 13),
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
                style: const TextStyle(
                  color: EverforestColors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              if (widget.onClearQueue != null)
                TextButton(
                  onPressed: widget.onClearQueue,
                  child: const Text('Clear', style: TextStyle(color: EverforestColors.red, fontSize: 12)),
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
            onReorder: widget.onReorder ?? (_, __) {},
            itemBuilder: (context, i) {
              final item = q[i];
              final isCurrent = i == widget.currentIndex;
              return Material(
                key: ValueKey('queue_item_${item.id}_$i'),
                color: isCurrent
                    ? EverforestColors.green.withValues(alpha: 0.12)
                    : Colors.transparent,
                child: ListTile(
                  dense: true,
                  leading: isCurrent
                      ? const Icon(Icons.volume_up_rounded, color: EverforestColors.green, size: 20)
                      : Text(
                          '${i + 1}',
                          style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
                        ),
                  title: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrent ? EverforestColors.green : EverforestColors.fg,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    item.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: EverforestColors.grey, fontSize: 11),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onRemove != null)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: EverforestColors.grey, size: 16),
                          onPressed: () => widget.onRemove!(i),
                        ),
                      const Icon(Icons.drag_handle_rounded, color: EverforestColors.grey, size: 18),
                    ],
                  ),
                  onTap: () => widget.onPlayIndex?.call(i),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopVolumeSlider() {
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
                color: EverforestColors.grey,
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
                  activeTrackColor: EverforestColors.green,
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
  Widget _buildMobileLayout(Size size) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Drag Handle with Fling Down Dismiss
            GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null && details.primaryVelocity! > 150) {
                  Navigator.pop(context);
                }
              },
              child: Center(
                child: Container(
                  width: 48,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: EverforestColors.fg, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: EverforestColors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'STREAMING · DSP',
                          style: TextStyle(
                            color: EverforestColors.fg,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.isDownloaded && widget.onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: EverforestColors.red, size: 22),
                          tooltip: 'Delete Song',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: EverforestColors.bg1,
                                title: const Text('Delete Song',
                                    style: TextStyle(color: EverforestColors.fg)),
                                content: Text(
                                  'Delete "${widget.title}" from downloaded library?',
                                  style: const TextStyle(color: EverforestColors.grey),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel',
                                        style: TextStyle(color: EverforestColors.grey)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      Navigator.pop(context);
                                      widget.onDelete?.call();
                                    },
                                    child: const Text('Delete',
                                        style: TextStyle(
                                            color: EverforestColors.red,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      else if (!widget.isDownloaded && widget.onDownload != null)
                        IconButton(
                          icon: const Icon(Icons.download_rounded,
                              color: EverforestColors.green, size: 22),
                          tooltip: 'Download Song',
                          onPressed: widget.onDownload,
                        ),
                      if (!widget.isOfflineLocal && widget.onDownloadOffline != null)
                        IconButton(
                          icon: const Icon(Icons.download_for_offline_rounded,
                              color: EverforestColors.aqua, size: 22),
                          tooltip: 'Save to this device (offline)',
                          onPressed: widget.onDownloadOffline,
                        ),
                      IconButton(
                        icon: const Icon(Icons.info_outline_rounded,
                            color: EverforestColors.grey, size: 22),
                        tooltip: 'Audio Specs',
                        onPressed: () => TrackMetadataModal.show(
                          context,
                          title: widget.title,
                          artist: widget.artist,
                          album: widget.album,
                          trackId: widget.trackId,
                          url: widget.streamUrl,
                          duration: widget.player.duration ?? Duration.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Center Artwork Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: _buildHeroCard(
                cardSize: math.min(size.width * 0.72, size.height * 0.32).clamp(170.0, 270.0),
              ),
            ),

            const SizedBox(height: 8),
            _buildModeSelectorPills(),

            const SizedBox(height: 10),
            _buildTrackInfo(),

            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: _buildWaveformBar(),
            ),

            const SizedBox(height: 8),
            _buildMobileTransport(),

            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildMobileDock(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard({required double cardSize}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: _cycleCardMode,
          onDoubleTapDown: (details) {
            final xFraction = details.localPosition.dx / constraints.maxWidth;
            if (xFraction < 0.35) {
              _seekRelative(const Duration(seconds: -10));
            } else if (xFraction > 0.65) {
              _seekRelative(const Duration(seconds: 10));
            } else {
              if (widget.player.playing) {
                widget.player.pause();
                _showFeedback('Paused', Icons.pause_rounded);
              } else {
                widget.player.play();
                _showFeedback('Playing', Icons.play_arrow_rounded);
              }
            }
          },
          onLongPress: () => TrackMetadataModal.show(
            context,
            title: widget.title,
            artist: widget.artist,
            album: widget.album,
            trackId: widget.trackId,
            url: widget.streamUrl,
            duration: widget.player.duration ?? Duration.zero,
          ),
          onVerticalDragUpdate: (details) {
            final delta = -details.primaryDelta! / 200.0;
            _adjustVolume(delta);
          },
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity! > 250) {
              Navigator.pop(context);
            }
          },
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! < -200) {
                widget.onNext();
              } else if (details.primaryVelocity! > 200) {
                widget.onPrev();
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
                    scale: Tween<double>(begin: 0.95, end: 1.0).animate(anim),
                    child: child,
                  ),
                ),
                child: _buildCenterCardContent(cardSize),
              ),

              // HUD Feedback
              if (_feedbackText != null)
                Positioned(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: EverforestColors.green.withValues(alpha: 0.5)),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 15),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_feedbackIcon != null) ...[
                          Icon(_feedbackIcon, color: EverforestColors.green, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _feedbackText!,
                          style: const TextStyle(
                            color: EverforestColors.fg,
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

  Widget _buildCenterCardContent(double cardSize) {
    switch (_cardMode) {
      case NowPlayingCardMode.artwork:
        return Container(
          key: const ValueKey('artwork_card'),
          width: cardSize,
          height: cardSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: widget.thumbnailUrl.isNotEmpty
                ? Image.network(
                    (kIsWeb && Uri.base.scheme == 'https' && widget.thumbnailUrl.startsWith('http://'))
                        ? widget.thumbnailUrl.replaceFirst('http://', 'https://')
                        : widget.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildFallbackArt(),
                  )
                : _buildFallbackArt(),
          ),
        );

      case NowPlayingCardMode.lyrics:
        return Container(
          key: const ValueKey('lyrics_card'),
          width: cardSize,
          height: cardSize,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: EverforestColors.bg1,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LyricsSyncViewer(
              title: widget.title,
              artist: widget.artist,
              player: widget.player,
              isEmbedded: true,
            ),
          ),
        );

      case NowPlayingCardMode.visualizer:
        return Container(
          key: const ValueKey('visualizer_card'),
          width: cardSize,
          height: cardSize,
          decoration: BoxDecoration(
            color: EverforestColors.bg1,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
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
                      return CustomPaint(
                        painter: AudioReactiveSpectrogramPainter(
                          position: pos,
                          trackId: widget.trackId,
                          playing: playing,
                          peakCaps: _peakCaps,
                          capVelocities: _capVelocities,
                          dspGains: AudioDspService.instance.bands,
                          bassBoost: AudioDspService.instance.bassBoost,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
    }
  }

  Widget _buildModeSelectorPills() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildModeDot(NowPlayingCardMode.artwork),
        const SizedBox(width: 6),
        _buildModeDot(NowPlayingCardMode.lyrics),
        const SizedBox(width: 6),
        _buildModeDot(NowPlayingCardMode.visualizer),
      ],
    );
  }

  Widget _buildModeDot(NowPlayingCardMode mode) {
    final active = _cardMode == mode;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: active ? 16 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? EverforestColors.green : Colors.white24,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildTrackInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          HeartButton(track: _currentTrack, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: EverforestColors.fg,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.artist.isNotEmpty ? widget.artist : 'Unknown Artist',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: EverforestColors.grey,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.playlist_add_rounded,
                color: EverforestColors.grey, size: 24),
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

  Widget _buildWaveformBar() {
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
              trackId: widget.trackId,
              height: 42,
              activeColor: EverforestColors.green,
              inactiveColor: Colors.white.withValues(alpha: 0.15),
              onSeek: (target) => widget.player.seek(target),
            );
          },
        );
      },
    );
  }

  Widget _buildPlayPauseCircle({double size = 58}) {
    return StreamBuilder<PlayerState>(
      stream: widget.player.playerStateStream,
      builder: (context, snap) {
        final state = snap.data;
        final playing = state?.playing ?? false;
        final loading = state?.processingState == ProcessingState.loading;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: EverforestColors.green,
            boxShadow: [
              BoxShadow(
                color: EverforestColors.green.withValues(alpha: 0.38),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(size / 2),
              onTap: loading
                  ? null
                  : (playing ? widget.player.pause : widget.player.play),
              child: Center(
                child: loading
                    ? SizedBox(
                        width: size * 0.42,
                        height: size * 0.42,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: EverforestColors.bg0,
                        ),
                      )
                    : Icon(
                        playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: EverforestColors.bg0,
                        size: size * 0.62,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileTransport() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              Icons.shuffle_rounded,
              color: _isShuffle ? EverforestColors.green : EverforestColors.grey,
              size: 22,
            ),
            onPressed: _toggleShuffle,
          ),
          GestureDetector(
            onLongPressStart: (_) => _startContinuousSeek(false),
            onLongPressEnd: (_) => _stopContinuousSeek(),
            child: IconButton(
              icon: const Icon(Icons.skip_previous_rounded,
                  color: EverforestColors.fg, size: 34),
              onPressed: widget.onPrev,
            ),
          ),
          _buildPlayPauseCircle(size: 56),
          GestureDetector(
            onLongPressStart: (_) => _startContinuousSeek(true),
            onLongPressEnd: (_) => _stopContinuousSeek(),
            child: IconButton(
              icon: const Icon(Icons.skip_next_rounded,
                  color: EverforestColors.fg, size: 34),
              onPressed: widget.onNext,
            ),
          ),
          IconButton(
            icon: Icon(
              _repeat == PlaybackRepeat.one
                  ? Icons.repeat_one_rounded
                  : Icons.repeat_rounded,
              color: _repeat != PlaybackRepeat.off
                  ? EverforestColors.green
                  : EverforestColors.grey,
              size: 22,
            ),
            onPressed: _toggleLoopMode,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDock() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildDockButton(
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
              icon: Icons.equalizer_rounded,
              label: 'Equalizer',
              active: false,
              onTap: () => PowerampEqualizerModal.show(context),
            ),
          ),
          Expanded(
            child: _buildDockButton(
              icon: Icons.queue_music_rounded,
              label: 'Queue',
              active: false,
              onTap: widget.onOpenQueue,
            ),
          ),
          Expanded(
            child: _buildDockButton(
              icon: widget.isOfflineLocal
                  ? Icons.check_circle_rounded
                  : Icons.download_for_offline_rounded,
              label: widget.isOfflineLocal ? 'On Device' : 'Download',
              active: widget.isOfflineLocal,
              onTap: widget.onDownloadOffline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackArt() {
    return Container(
      color: EverforestColors.bg1,
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: EverforestColors.green.withValues(alpha: 0.8),
          size: 70,
        ),
      ),
    );
  }

  Widget _buildDockButton({
    required IconData icon,
    required String label,
    required bool active,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active ? EverforestColors.green : EverforestColors.grey,
              size: 19,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active ? EverforestColors.green : EverforestColors.grey,
                fontSize: 10,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

