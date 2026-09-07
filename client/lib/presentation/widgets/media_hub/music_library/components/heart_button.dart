import 'package:flutter/material.dart';
import '../../../../../core/domain_repositories.dart';
import '../../../../../theme/app_skin_manager.dart';

class HeartButton extends StatelessWidget {
  const HeartButton({
    super.key,
    required this.track,
    this.size = 22,
    this.activeColor,
    this.inactiveColor,
  });

  final MusicTrack track;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final effectiveActiveColor = activeColor ?? skin.red;
    final effectiveInactiveColor = inactiveColor ?? skin.textMuted;

    return ValueListenableBuilder<Set<String>>(
      valueListenable: MusicRepository.instance.likedTrackIds,
      builder: (context, likedIds, _) {
        final isLiked = likedIds.contains(track.id);
        return IconButton(
          iconSize: size,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: isLiked ? 'Remove from Liked Songs' : 'Add to Liked Songs',
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              isLiked
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              key: ValueKey<bool>(isLiked),
              color: isLiked ? effectiveActiveColor : effectiveInactiveColor,
              size: size,
            ),
          ),
          onPressed: () => MusicRepository.instance.toggleLike(track),
        );
      },
    );
  }
}
