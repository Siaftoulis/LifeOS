import 'package:flutter/material.dart';
import '../../../../theme/everforest_colors.dart';

typedef QueueTrackItem = ({
  String id,
  String url,
  String title,
  String artist,
  String thumbnail,
  String album,
});

class PowerampQueueSheet extends StatefulWidget {
  final List<QueueTrackItem> queue;
  final int currentIndex;
  final ValueChanged<int> onPlayIndex;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<int> onRemove;
  final VoidCallback onClear;

  const PowerampQueueSheet({
    super.key,
    required this.queue,
    required this.currentIndex,
    required this.onPlayIndex,
    required this.onReorder,
    required this.onRemove,
    required this.onClear,
  });

  static void show(
    BuildContext context, {
    required List<QueueTrackItem> queue,
    required int currentIndex,
    required ValueChanged<int> onPlayIndex,
    required void Function(int oldIndex, int newIndex) onReorder,
    required ValueChanged<int> onRemove,
    required VoidCallback onClear,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PowerampQueueSheet(
        queue: queue,
        currentIndex: currentIndex,
        onPlayIndex: onPlayIndex,
        onReorder: onReorder,
        onRemove: onRemove,
        onClear: onClear,
      ),
    );
  }

  @override
  State<PowerampQueueSheet> createState() => _PowerampQueueSheetState();
}

class _PowerampQueueSheetState extends State<PowerampQueueSheet> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final queue = widget.queue;

    return Container(
      height: size.height * 0.88,
      decoration: BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 40,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag Handle
          Center(
            child: Container(
              width: 48,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: EverforestColors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.queue_music_rounded,
                    color: EverforestColors.green,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PLAYING QUEUE',
                        style: TextStyle(
                          color: EverforestColors.fg,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${queue.length} Tracks in Queue',
                        style: const TextStyle(
                          color: EverforestColors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (queue.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      widget.onClear();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.clear_all_rounded, color: EverforestColors.red, size: 18),
                    label: const Text('Clear', style: TextStyle(color: EverforestColors.red, fontSize: 13)),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          const Divider(color: Colors.white10, height: 1),

          // Reorderable List of Queue Tracks
          Expanded(
            child: queue.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.queue_music_rounded, color: EverforestColors.grey, size: 48),
                        SizedBox(height: 12),
                        Text(
                          'Queue is empty',
                          style: TextStyle(color: EverforestColors.grey, fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: queue.length,
                    onReorder: (oldIdx, newIdx) {
                      setState(() {
                        widget.onReorder(oldIdx, newIdx);
                      });
                    },
                    itemBuilder: (context, index) {
                      final item = queue[index];
                      final isCurrent = index == widget.currentIndex;

                      return Dismissible(
                        key: ValueKey('${item.id}_$index'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: EverforestColors.red.withValues(alpha: 0.8),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          setState(() {
                            widget.onRemove(index);
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? EverforestColors.green.withValues(alpha: 0.12)
                                : EverforestColors.bg1,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isCurrent
                                  ? EverforestColors.green.withValues(alpha: 0.4)
                                  : Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ReorderableDragStartListener(
                                  index: index,
                                  child: const Icon(
                                    Icons.drag_handle_rounded,
                                    color: EverforestColors.grey,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: item.thumbnail.isNotEmpty
                                        ? Image.network(
                                            item.thumbnail,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                                          )
                                        : _buildPlaceholder(),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isCurrent ? EverforestColors.green : EverforestColors.fg,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              item.artist.isNotEmpty ? item.artist : 'Unknown Artist',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: EverforestColors.grey,
                                fontSize: 12,
                              ),
                            ),
                            trailing: isCurrent
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: EverforestColors.green.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'PLAYING',
                                      style: TextStyle(
                                        color: EverforestColors.green,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.close_rounded, color: EverforestColors.grey, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        widget.onRemove(index);
                                      });
                                    },
                                  ),
                            onTap: () {
                              widget.onPlayIndex(index);
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [EverforestColors.blue, EverforestColors.purple],
        ),
      ),
      child: const Icon(Icons.music_note_rounded, color: Colors.white70, size: 20),
    );
  }
}
