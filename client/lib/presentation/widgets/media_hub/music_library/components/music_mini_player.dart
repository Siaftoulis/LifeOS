import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../../core/music_playback/playback_controller.dart';
import '../../../../../theme/app_skin_manager.dart';
import '../music_formatters.dart';

class MusicMiniPlayer extends StatelessWidget {
  const MusicMiniPlayer({
    super.key,
    required this.playbackController,
    required this.currentTrackId,
    required this.currentTitle,
    required this.currentArtist,
    required this.currentThumbnail,
    required this.onTap,
    required this.onOpenLyrics,
  });

  final PlaybackController playbackController;
  final String currentTrackId;
  final String currentTitle;
  final String currentArtist;
  final String currentThumbnail;
  final VoidCallback onTap;
  final VoidCallback onOpenLyrics;

  Widget _buildMiniPlaceholder(AppSkin skin) {
    return Container(
      decoration: BoxDecoration(
        color: skin.bg2,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Icon(
        Icons.graphic_eq_rounded,
        color: skin.accent,
        size: 26,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: playbackController,
      builder: (context, _) {
        final skin = context.skin;
        final player = playbackController.player;
        final activeItem = playbackController.currentItem;
        final effectiveTrackId = activeItem?.id.isNotEmpty == true ? activeItem!.id : currentTrackId;
        final effectiveTitle = activeItem?.title.isNotEmpty == true ? activeItem!.title : currentTitle;
        final effectiveArtist = activeItem?.artist.isNotEmpty == true ? activeItem!.artist : currentArtist;
        final effectiveThumbnail = activeItem?.thumbnail.isNotEmpty == true ? activeItem!.thumbnail : currentThumbnail;

        if (player == null || effectiveTrackId.isEmpty || activeItem == null) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
      onTap: onTap,
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < -150) {
          onTap();
        }
      },
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -200) {
            playbackController.next();
          } else if (details.primaryVelocity! > 200) {
            playbackController.previous();
          }
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              color: skin.bg1.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: skin.isOled ? 0.7 : 0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: StreamBuilder<PlayerState>(
              stream: player.playerStateStream,
              builder: (context, snapshot) {
                final state = snapshot.data;
                final playing = state?.playing ?? false;
                final loading =
                    state?.processingState == ProcessingState.loading ||
                        state?.processingState == ProcessingState.buffering;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
                      child: Row(
                        children: [
                          Hero(
                            tag:
                                'now_playing_artwork_${effectiveTrackId.isEmpty ? "empty" : effectiveTrackId}',
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: skin.bg2,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: effectiveThumbnail.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        sanitizeMusicThumbnailUrl(
                                            effectiveThumbnail),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _buildMiniPlaceholder(skin),
                                      ),
                                    )
                                  : _buildMiniPlaceholder(skin),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  effectiveTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: skin.fg,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        effectiveArtist.isNotEmpty
                                            ? effectiveArtist
                                            : 'LifeOS Audio',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: skin.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    if (playbackController.activeStreamType.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: skin.accent.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: skin.accent.withValues(alpha: 0.35),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.bolt_rounded, size: 10, color: skin.accent),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${playbackController.activeStreamType.toUpperCase()}${playbackController.activeBitrate > 0 ? " ${playbackController.activeBitrate ~/ 1000}K" : ""}',
                                              style: TextStyle(
                                                color: skin.accent,
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            iconSize: 32,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            tooltip: playing ? 'Pause' : 'Play',
                            icon: loading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: skin.accent,
                                    ),
                                  )
                                : Icon(
                                    playing
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: skin.fg,
                                    size: 30,
                                  ),
                            onPressed: loading
                                ? null
                                : playbackController.togglePlayPause,
                          ),
                        ],
                      ),
                    ),
                    // Poweramp 1:1 Progress Scrubber Track
                    StreamBuilder<Duration>(
                      stream: player.positionStream,
                      builder: (context, posSnap) {
                        final pos = posSnap.data ?? Duration.zero;
                        final dur = player.duration ?? Duration.zero;
                        final totalMs = dur.inMilliseconds.toDouble();
                        final currentMs = pos.inMilliseconds.toDouble().clamp(0.0, totalMs > 0 ? totalMs : 1.0);
                        return SizedBox(
                          height: 16,
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3.0,
                              activeTrackColor: skin.fg.withValues(alpha: 0.75),
                              inactiveTrackColor: Colors.white12,
                              thumbColor: skin.fg,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4.5),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                            ),
                            child: Slider(
                              value: currentMs,
                              min: 0.0,
                              max: totalMs > 0 ? totalMs : 1.0,
                              onChanged: (v) {
                                playbackController.seek(Duration(milliseconds: v.round()));
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 2),
                  ],
                );
              },
            ),
          ),
        ),
      ),
        );
      },
    );
  }
}
