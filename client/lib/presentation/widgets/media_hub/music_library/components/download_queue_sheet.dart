import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../core/domain_repositories.dart';
import '../../../../../theme/app_skin_manager.dart';

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
  bool _isFetching = false;
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
    _pollTimer = null;
    MusicRepository.instance.downloadQueue.removeListener(_onQueueUpdated);
    super.dispose();
  }

  void _onQueueUpdated() {
    if (mounted) _checkAndSchedulePolling();
  }

  void _checkAndSchedulePolling() {
    if (!mounted) return;
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
        if (!mounted) return;
        if (_isFetching) return;
        _isFetching = true;
        try {
          final prevQueue = MusicRepository.instance.downloadQueue.value;
          final prevActiveIds = prevQueue
              .where((i) {
                final s = i.status.toUpperCase();
                return s == 'PENDING' || s == 'DOWNLOADING';
              })
              .map((i) => i.id)
              .toSet();

          await MusicRepository.instance.loadDownloadQueue();
          if (!mounted) return;

          final newQueue = MusicRepository.instance.downloadQueue.value;
          // Refresh library only if an item transitioned to completed
          final newlyCompleted = newQueue.any((i) =>
              prevActiveIds.contains(i.id) &&
              i.status.toUpperCase() == 'COMPLETED');
          if (newlyCompleted) {
            MusicRepository.instance.refresh();
          }

          final stillActive = newQueue.any((i) {
            final s = i.status.toUpperCase();
            return s == 'PENDING' || s == 'DOWNLOADING';
          });
          if (!stillActive) {
            _pollTimer?.cancel();
            _pollTimer = null;
          }
        } catch (e) {
          debugPrint('Download queue poll error: $e');
        } finally {
          _isFetching = false;
        }
      });
    }
  }

  Color _statusColor(String status, AppSkin skin) {
    switch (status.toUpperCase()) {
      case 'DOWNLOADING':
        return skin.aqua;
      case 'COMPLETED':
        return skin.accent;
      case 'FAILED':
        return skin.red;
      case 'CANCELLED':
        return skin.textMuted;
      default:
        return skin.yellow;
    }
  }

  String _stageText(DownloadQueueItem item) {
    final s = item.status.toUpperCase();
    if (s == 'DOWNLOADING') {
      switch (item.stage.toLowerCase()) {
        case 'resolving':
          return 'RESOLVING SOURCE';
        case 'tagging':
          return 'TAGGING & ART';
        default:
          return 'DOWNLOADING';
      }
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: skin.bg0,
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
                    color: skin.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.download_rounded,
                      color: skin.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Download Manager',
                    style: TextStyle(
                      color: skin.fg,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  icon: Icon(Icons.clear_all_rounded,
                      color: skin.textMuted, size: 18),
                  label: Text('Clear Done',
                      style: TextStyle(color: skin.textMuted)),
                  onPressed: () async {
                    await MusicRepository.instance.clearCompletedDownloads();
                    await MusicRepository.instance.loadDownloadQueue();
                  },
                ),
              ],
            ),
          ),
          Divider(color: skin.bg2, height: 1),
          Expanded(
            child: ValueListenableBuilder<List<DownloadQueueItem>>(
              valueListenable: MusicRepository.instance.downloadQueue,
              builder: (context, queue, _) {
                if (queue.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_done_rounded,
                            color: skin.textMuted, size: 44),
                        const SizedBox(height: 12),
                        Text('Download queue is empty',
                            style: TextStyle(
                                color: skin.textMuted, fontSize: 15)),
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
                    final color = _statusColor(item.status, skin);
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
                        color: skin.bg1,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: isFailed
                                ? skin.red.withValues(alpha: 0.3)
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
                                      color: skin.bg0,
                                      child: Icon(
                                          Icons.music_note_rounded,
                                          color: skin.aqua,
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
                                      style: TextStyle(
                                        color: skin.fg,
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
                                      style: TextStyle(
                                          color: skin.textMuted,
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              if (item.qualityMode.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (item.qualityMode == 'best' ? skin.accent : Colors.blueAccent).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    item.qualityMode == 'best' ? '💎 BEST' : '⚡ FAST',
                                    style: TextStyle(
                                      color: item.qualityMode == 'best' ? skin.accent : Colors.blueAccent,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _stageText(item),
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
                                  icon: Icon(Icons.close_rounded,
                                      color: skin.textMuted, size: 18),
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
                                backgroundColor: skin.bg0,
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
                                  color: skin.red
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: skin.red
                                          .withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.error_outline_rounded,
                                        color: skin.red,
                                        size: 15),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item.errorMessage,
                                        maxLines: isExpanded ? null : 2,
                                        overflow: isExpanded
                                            ? null
                                            : TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: skin.red,
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
                                      color: skin.red,
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
