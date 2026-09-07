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
                            valueColor: AlwaysStoppedAnimation<Color>(skin.accent),
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
                                'now_playing_artwork_${effectiveTrackId.isEmpty ? "empty" : effectiveTrackId}',
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: skin.accent.withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: effectiveThumbnail.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
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
                          const SizedBox(width: 14),
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
                                        color: skin.accent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'DSP ACTIVE',
                                        style: TextStyle(
                                          color: skin.accent,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
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
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.lyrics_rounded),
                            color: skin.textMuted,
                            iconSize: 22,
                            tooltip: 'Live Lyrics',
                            onPressed: onOpenLyrics,
                          ),
                          IconButton(
                            iconSize: 38,
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
                                    size: 32,
                                  ),
                            onPressed: loading
                                ? null
                                : playbackController.togglePlayPause,
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded),
                            color: skin.fg,
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
