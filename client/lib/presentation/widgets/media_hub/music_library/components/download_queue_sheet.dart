import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../core/domain_repositories.dart';
import '../../../../../theme/everforest_colors.dart';

class DownloadQueueSheet extends StatefulWidget {
  const DownloadQueueSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DownloadQueueSheet(),
    );
  }

  @override
  State<DownloadQueueSheet> createState() => _DownloadQueueSheetState();
}

class _DownloadQueueSheetState extends State<DownloadQueueSheet> {
  Timer? _pollTimer;
  final Set<String> _expandedErrors = {};

  @override
  void initState() {
    super.initState();
    MusicRepository.instance.loadDownloadQueue().then((_) {
      if (mounted) _checkAndSchedulePolling();
    });
    MusicRepository.instance.downloadQueue.addListener(_onQueueUpdated);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    MusicRepository.instance.downloadQueue.removeListener(_onQueueUpdated);
    super.dispose();
  }

  void _onQueueUpdated() {
    if (mounted) _checkAndSchedulePolling();
  }

  void _checkAndSchedulePolling() {
    final queue = MusicRepository.instance.downloadQueue.value;
    final hasActive = queue.any((item) {
      final s = item.status.toUpperCase();
      return s == 'PENDING' || s == 'DOWNLOADING';
    });

    if (!hasActive) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }

    if (_pollTimer == null || !_pollTimer!.isActive) {
      _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
        await MusicRepository.instance.loadDownloadQueue();
        if (MusicRepository.instance.downloadQueue.value
            .any((i) => i.status.toUpperCase() == 'COMPLETED')) {
          MusicRepository.instance.refresh();
        }
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DOWNLOADING':
        return EverforestColors.aqua;
      case 'COMPLETED':
        return EverforestColors.green;
      case 'FAILED':
        return EverforestColors.red;
      case 'CANCELLED':
        return EverforestColors.grey;
      default:
        return EverforestColors.yellow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 40,
            offset: Offset(0, -10),
          )
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: EverforestColors.aqua.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.download_rounded,
                      color: EverforestColors.aqua, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Download Manager',
                    style: TextStyle(
                      color: EverforestColors.fg,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.clear_all_rounded,
                      color: EverforestColors.grey, size: 18),
                  label: const Text('Clear Done',
                      style: TextStyle(color: EverforestColors.grey)),
                  onPressed: () async {
                    await MusicRepository.instance.clearCompletedDownloads();
                    await MusicRepository.instance.loadDownloadQueue();
                  },
                ),
              ],
            ),
          ),
          const Divider(color: EverforestColors.bg2, height: 1),
          Expanded(
            child: ValueListenableBuilder<List<DownloadQueueItem>>(
              valueListenable: MusicRepository.instance.downloadQueue,
              builder: (context, queue, _) {
                if (queue.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_done_rounded,
                            color: EverforestColors.grey, size: 44),
                        SizedBox(height: 12),
                        Text('Download queue is empty',
                            style: TextStyle(
                                color: EverforestColors.grey, fontSize: 15)),
                      ],
                    ),
                  );
                }

                final metadata = MusicRepository.instance.knownTrackMetadata;

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: queue.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final item = queue[i];
                    final color = _statusColor(item.status);
                    final isFailed = item.status.toUpperCase() == 'FAILED';
                    final isPendingOrDownloading =
                        item.status.toUpperCase() == 'PENDING' ||
                            item.status.toUpperCase() == 'DOWNLOADING';
                    final title = item.displayTitle(metadata);
                    final artist = item.displayArtist(metadata);
                    final thumb = item.displayThumbnail(metadata);
                    final isExpanded = _expandedErrors.contains(item.id);

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: EverforestColors.bg1,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: isFailed
                                ? EverforestColors.red.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (thumb.isNotEmpty) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    thumb,
                                    width: 38,
                                    height: 38,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 38,
                                      height: 38,
                                      color: EverforestColors.bg0,
                                      child: const Icon(
                                          Icons.music_note_rounded,
                                          color: EverforestColors.aqua,
                                          size: 18),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: EverforestColors.fg,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      artist.isNotEmpty
                                          ? artist
                                          : 'LifeOS Library',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: EverforestColors.grey,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.status.toUpperCase(),
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isPendingOrDownloading) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded,
                                      color: EverforestColors.grey, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Cancel',
                                  onPressed: () async {
                                    await MusicRepository.instance
                                        .cancelDownload(item.id);
                                    await MusicRepository.instance
                                        .loadDownloadQueue();
                                  },
                                ),
                              ],
                            ],
                          ),
                          if (item.status.toUpperCase() == 'DOWNLOADING') ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (item.progress != null &&
                                        item.progress! > 0)
                                    ? item.progress
                                    : null,
                                backgroundColor: EverforestColors.bg0,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(color),
                                minHeight: 4,
                              ),
                            ),
                          ],
                          if (isFailed && item.errorMessage.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedErrors.remove(item.id);
                                  } else {
                                    _expandedErrors.add(item.id);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: EverforestColors.red
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: EverforestColors.red
                                          .withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.error_outline_rounded,
                                        color: EverforestColors.red,
                                        size: 15),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item.errorMessage,
                                        maxLines: isExpanded ? null : 2,
                                        overflow: isExpanded
                                            ? null
                                            : TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: EverforestColors.red,
                                          fontSize: 11,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      isExpanded
                                          ? Icons.expand_less_rounded
                                          : Icons.expand_more_rounded,
                                      color: EverforestColors.red,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
