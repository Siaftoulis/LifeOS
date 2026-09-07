import 'package:flutter/material.dart';
import '../../../../../core/domain_repositories.dart';
import '../../../../../theme/app_skin_manager.dart';

typedef SmartMixEntry = ({
  String desc,
  IconData icon,
  Color color,
  List<MusicTrack> list
});

class SmartMixesSliver extends StatelessWidget {
  const SmartMixesSliver({
    super.key,
    required this.smartMixes,
    required this.canPlay,
    required this.onPlayTrackList,
  });

  final Map<String, SmartMixEntry> smartMixes;
  final bool canPlay;
  final void Function(List<MusicTrack> list, int index) onPlayTrackList;

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final keys = smartMixes.keys.toList();
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 320,
          mainAxisExtent: 110,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final key = keys[i];
            final mix = smartMixes[key]!;
            return InkWell(
              onTap: canPlay && mix.list.isNotEmpty
                  ? () => onPlayTrackList(mix.list, 0)
                  : null,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: skin.bg1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: mix.color.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: mix.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(mix.icon, color: mix.color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: skin.fg,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${mix.list.length} tracks · ${mix.desc}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: skin.textMuted, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    if (canPlay)
                      IconButton(
                        icon: Icon(Icons.play_circle_fill_rounded,
                            color: mix.color, size: 34),
                        tooltip: 'Play Mix',
                        onPressed: mix.list.isNotEmpty
                            ? () => onPlayTrackList(mix.list, 0)
                            : null,
                      )
                    else
                      Icon(Icons.phonelink_lock_rounded,
                          color: skin.textMuted, size: 20),
                  ],
                ),
              ),
            );
          },
          childCount: keys.length,
        ),
      ),
    );
  }
}
