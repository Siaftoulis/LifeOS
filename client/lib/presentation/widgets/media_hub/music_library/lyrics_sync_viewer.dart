import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../theme/everforest_colors.dart';
import '../../../../api_client.dart';
import '../../../../core/telemetry/telemetry_reporter.dart';

/// True Centered Karaoke Lyrics Viewer inspired by Apple Music & Spotify.
/// The active lyric line is strictly anchored at the exact vertical center (50%)
/// of the viewport while the lyrics stream smoothly through it.
class LyricsSyncViewer extends StatefulWidget {
  const LyricsSyncViewer({
    super.key,
    required this.title,
    required this.artist,
    required this.player,
    this.isEmbedded = false,
  });

  final String title;
  final String artist;
  final AudioPlayer player;
  final bool isEmbedded;

  @override
  State<LyricsSyncViewer> createState() => _LyricsSyncViewerState();
}

class _LyricsSyncViewerState extends State<LyricsSyncViewer> {
  static const double _kItemHeight = 62.0;

  final ScrollController _scroll = ScrollController();
  StreamSubscription<Duration>? _posSub;

  List<Map<String, dynamic>> _lines = [];
  bool _loading = true;
  bool _studying = false;
  int _active = -1;
  bool _isAutoScrolling = false;

  @override
  void initState() {
    super.initState();
    _fetch();
    _subscribeToPosition();
  }

  @override
  void didUpdateWidget(covariant LyricsSyncViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title || oldWidget.artist != widget.artist) {
      setState(() {
        _lines = [];
        _loading = true;
        _active = -1;
      });
      _fetch();
    }
    if (oldWidget.player != widget.player) {
      _posSub?.cancel();
      _subscribeToPosition();
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _subscribeToPosition() {
    _posSub?.cancel();
    _posSub = widget.player.positionStream.listen((pos) {
      _handlePosition(pos.inMilliseconds / 1000.0);
    });
  }

  void _handlePosition(double position) {
    if (_lines.isEmpty || !mounted) return;

    int active = -1;
    for (var i = 0; i < _lines.length; i++) {
      final t = (_lines[i]['time'] as num?)?.toDouble() ?? -1;
      if (t >= 0 && position >= t) {
        active = i;
      }
    }

    if (active != _active) {
      setState(() => _active = active);
      _scrollToActive(active);
    }
  }

  void _scrollToActive(int index) {
    if (index < 0 || !_scroll.hasClients || _isAutoScrolling) return;

    // Exact mathematical center scroll offset
    final targetOffset = (index * _kItemHeight).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );

    _isAutoScrolling = true;
    _scroll
        .animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        )
        .then((_) {
          _isAutoScrolling = false;
        })
        .catchError((_) {
          _isAutoScrolling = false;
        });
  }

  Future<void> _fetch() async {
    try {
      final query = Uri(queryParameters: {'title': widget.title, 'artist': widget.artist}).query;
      final res = await ApiClient.instance.getDaemon('/api/v1/music/lyrics?$query');
      if (mounted) {
        setState(() {
          _lines = res is List ? res.cast<Map<String, dynamic>>() : [];
          _loading = false;
        });
        // Initial positioning
        final curSec = widget.player.position.inMilliseconds / 1000.0;
        _handlePosition(curSec);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _studyCheck() async {
    if (_studying) return;
    setState(() => _studying = true);
    final res = await TelemetryReporter.instance.trackAndFlush(
      'music',
      'lyrics_studied',
      {'track': widget.title, 'artist': widget.artist},
    );
    if (!mounted) return;
    setState(() => _studying = false);
    final awarded = (res?['awarded'] as num?)?.toInt() ?? 0;
    final balance = (res?['balance'] as num?)?.toInt();
    final msg = awarded > 0
        ? (balance != null ? '+2 stars earned! Balance: $balance' : '+2 stars earned!')
        : 'Already counted today - nice studying!';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: EverforestColors.bg1),
    );
  }

  void _seekToLine(int index) {
    if (index < 0 || index >= _lines.length) return;
    final t = (_lines[index]['time'] as num?)?.toDouble() ?? -1;
    if (t >= 0) {
      widget.player.seek(Duration(milliseconds: (t * 1000).round()));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEmbedded) {
      return _buildCenteredLyricsBody();
    }

    return Container(
      decoration: const BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: EverforestColors.fg,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: EverforestColors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: _studying
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: EverforestColors.bg0,
                        ),
                      )
                    : const Icon(Icons.star_rounded, size: 16),
                label: const Text('Study (+2)', style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EverforestColors.yellow,
                  foregroundColor: EverforestColors.bg0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                onPressed: _studyCheck,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(child: _buildCenteredLyricsBody()),
        ],
      ),
    );
  }

  Widget _buildCenteredLyricsBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: EverforestColors.green));
    }
    if (_lines.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lyrics_rounded, color: EverforestColors.grey, size: 36),
            const SizedBox(height: 8),
            Text(
              'No synchronized lyrics available',
              style: TextStyle(
                color: EverforestColors.grey.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Vertical padding to ensure the active line (and line 0) aligns to the exact center
        final verticalPadding = ((constraints.maxHeight - _kItemHeight) / 2.0).clamp(20.0, 500.0);

        return ShaderMask(
          shaderCallback: (rect) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black,
                Colors.black,
                Colors.transparent,
              ],
              stops: [0.0, 0.18, 0.82, 1.0],
            ).createShader(rect);
          },
          blendMode: BlendMode.dstIn,
          child: ListView.builder(
            controller: _scroll,
            physics: const BouncingScrollPhysics(),
            itemExtent: _kItemHeight,
            padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 16),
            itemCount: _lines.length,
            itemBuilder: (context, i) {
              final time = (_lines[i]['time'] as num?)?.toDouble() ?? -1;
              final text = _lines[i]['text']?.toString() ?? '';
              final isActive = time >= 0 && i == _active;
              final isPast = time >= 0 && i < _active;

              return InkWell(
                onTap: time >= 0 ? () => _seekToLine(i) : null,
                borderRadius: BorderRadius.circular(16),
                splashColor: EverforestColors.green.withValues(alpha: 0.12),
                child: Container(
                  height: _kItemHeight,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: time < 0
                          ? EverforestColors.grey
                          : isActive
                              ? EverforestColors.green
                              : isPast
                                  ? EverforestColors.fg.withValues(alpha: 0.30)
                                  : EverforestColors.fg.withValues(alpha: 0.50),
                      fontSize: isActive ? 21 : 14.5,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      letterSpacing: isActive ? -0.3 : 0,
                      shadows: isActive
                          ? [
                              Shadow(
                                color: EverforestColors.green.withValues(alpha: 0.6),
                                blurRadius: 18,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}