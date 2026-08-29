import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api_client.dart';
import '../../core/gallery_sync_engine.dart';
import '../../presentation/widgets/media_hub/photo_video_gallery/aves_viewer_screen.dart';
import '../../presentation/widgets/media_hub/photo_video_gallery/gallery_item.dart';
import '../../theme/everforest_colors.dart';

class GalleryTimelineView extends StatelessWidget {
  const GalleryTimelineView({
    super.key,
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.onRefresh,
    required this.scrollController,
  });

  final List<GalleryItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Future<void> Function() onRefresh;
  final ScrollController scrollController;

  Map<String, List<GalleryItem>> _groupByDate(List<GalleryItem> list) {
    final Map<String, List<GalleryItem>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final item in list) {
      final itemDate = DateTime(item.date.year, item.date.month, item.date.day);
      String key;
      if (itemDate == today) {
        key = 'Today';
      } else if (itemDate == yesterday) {
        key = 'Yesterday';
      } else if (itemDate.year == now.year) {
        key = DateFormat('EEEE, d MMMM').format(item.date);
      } else {
        key = DateFormat('d MMMM yyyy').format(item.date);
      }
      groups.putIfAbsent(key, () => []).add(item);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: EverforestColors.green),
      );
    }

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: EverforestColors.green,
        backgroundColor: EverforestColors.bg1,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_queue_rounded,
                      color: EverforestColors.grey, size: 56),
                  SizedBox(height: 16),
                  Text(
                    'No cloud photos yet',
                    style: TextStyle(
                      color: EverforestColors.fg,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap "Sync Now" to back up your local photos to the server.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: EverforestColors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final dateGroups = _groupByDate(items);
    final isWide = MediaQuery.of(context).size.width >= 700;
    final crossAxisCount = isWide ? 5 : 3;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: EverforestColors.green,
      backgroundColor: EverforestColors.bg1,
      child: CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Live Sync Status Banner
          SliverToBoxAdapter(
            child: _buildSyncStatusBanner(context),
          ),

          // Date Groups
          ...dateGroups.entries.map((entry) {
            final dateTitle = entry.key;
            final groupItems = entry.value;

            return SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateTitle,
                          style: const TextStyle(
                            color: EverforestColors.fg,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${groupItems.length} items',
                          style: const TextStyle(
                            color: EverforestColors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = groupItems[index];
                        final globalIndex = items.indexOf(item);

                        return _buildPhotoTile(context, item, globalIndex);
                      },
                      childCount: groupItems.length,
                    ),
                  ),
                ),
              ],
            );
          }),

          // Pagination Loader
          if (isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: EverforestColors.green,
                    ),
                  ),
                ),
              ),
            )
          else
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildSyncStatusBanner(BuildContext context) {
    final syncEngine = GallerySyncEngine.instance;

    return ValueListenableBuilder<bool>(
      valueListenable: syncEngine.isSyncing,
      builder: (context, isSyncing, _) {
        return ValueListenableBuilder<int>(
          valueListenable: syncEngine.totalToSync,
          builder: (context, total, _) {
            return ValueListenableBuilder<int>(
              valueListenable: syncEngine.syncedCount,
              builder: (context, synced, _) {
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSyncing
                        ? EverforestColors.aqua.withValues(alpha: 0.15)
                        : EverforestColors.bg1,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSyncing
                          ? EverforestColors.aqua.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSyncing
                              ? EverforestColors.aqua.withValues(alpha: 0.2)
                              : EverforestColors.green.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSyncing
                              ? Icons.sync_rounded
                              : Icons.cloud_done_rounded,
                          color: isSyncing
                              ? EverforestColors.aqua
                              : EverforestColors.green,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSyncing
                                  ? 'Backing up photos ($synced / $total)...'
                                  : 'Vault Photo Backup Active',
                              style: const TextStyle(
                                color: EverforestColors.fg,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isSyncing
                                  ? 'Content-addressable SHA256 deduplication'
                                  : 'All device photos synced with server vault',
                              style: const TextStyle(
                                color: EverforestColors.grey,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSyncing)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: EverforestColors.aqua,
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          icon: const Icon(Icons.sync_rounded, size: 16),
                          label: const Text('Sync Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EverforestColors.green,
                            foregroundColor: EverforestColors.bg0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => syncEngine.startSync(),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPhotoTile(BuildContext context, GalleryItem item, int index) {
    final thumbUrl =
        '${ApiClient.instance.daemonUrl}/api/v1/gallery/thumbnail?id=${item.id}';
    final isVideo = item.type == 'video';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AvesViewerScreen(
              items: items,
              initialIndex: index,
            ),
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ExtendedImage.network(
              thumbUrl,
              fit: BoxFit.cover,
              cache: true,
              loadStateChanged: (state) {
                switch (state.extendedImageLoadState) {
                  case LoadState.loading:
                    return Container(
                      color: EverforestColors.bg1,
                      child: const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: EverforestColors.green,
                          ),
                        ),
                      ),
                    );
                  case LoadState.failed:
                    return Container(
                      color: EverforestColors.bg1,
                      child: const Icon(
                        Icons.broken_image_rounded,
                        color: EverforestColors.grey,
                        size: 24,
                      ),
                    );
                  case LoadState.completed:
                    return null;
                }
              },
            ),
          ),
          if (isVideo)
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
