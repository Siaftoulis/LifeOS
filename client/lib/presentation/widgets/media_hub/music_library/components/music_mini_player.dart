import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../../core/music_playback/playback_controller.dart';
import '../../../../../theme/everforest_colors.dart';
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

  Widget _buildMiniPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        color: EverforestColors.bg2,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: const Icon(
        Icons.graphic_eq_rounded,
        color: EverforestColors.green,
        size: 26,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = playbackController.player;
    if (player == null ||
        currentTrackId.isEmpty ||
        playbackController.currentItem == null) {
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
              color: EverforestColors.bg1.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 20,
                  offset: Offset(0, 8),
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
                    StreamBuilder<Duration>(
                      stream: player.positionStream,
                      builder: (context, posSnap) {
                        final pos = posSnap.data ?? Duration.zero;
                        final dur = player.duration ?? Duration.zero;
                        final progress = (dur.inMilliseconds > 0)
                            ? (pos.inMilliseconds / dur.inMilliseconds)
                                .clamp(0.0, 1.0)
                            : 0.0;
                        return ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 2.5,
                            backgroundColor: Colors.transparent,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                EverforestColors.green),
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Hero(
                            tag:
                                'now_playing_artwork_${currentTrackId.isEmpty ? "empty" : currentTrackId}',
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: EverforestColors.green
                                        .withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: currentThumbnail.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        sanitizeMusicThumbnailUrl(
                                            currentThumbnail),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _buildMiniPlaceholder(),
                                      ),
                                    )
                                  : _buildMiniPlaceholder(),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currentTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: EverforestColors.fg,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4.5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: EverforestColors.green
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'DSP ACTIVE',
                                        style: TextStyle(
                                          color: EverforestColors.green,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        currentArtist.isNotEmpty
                                            ? currentArtist
                                            : 'LifeOS Audio',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: EverforestColors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.lyrics_rounded),
                            color: EverforestColors.grey,
                            iconSize: 22,
                            tooltip: 'Live Lyrics',
                            onPressed: onOpenLyrics,
                          ),
                          IconButton(
                            iconSize: 38,
                            tooltip: playing ? 'Pause' : 'Play',
                            icon: loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: EverforestColors.green,
                                    ),
                                  )
                                : Icon(
                                    playing
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: EverforestColors.fg,
                                    size: 32,
                                  ),
                            onPressed: loading
                                ? null
                                : playbackController.togglePlayPause,
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded),
                            color: EverforestColors.fg,
                            iconSize: 28,
                            tooltip: 'Next Track',
                            onPressed: playbackController.next,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
