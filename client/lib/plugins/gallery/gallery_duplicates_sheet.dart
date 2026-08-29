import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../core/cloud_gallery_service.dart';
import '../../theme/everforest_colors.dart';

class GalleryDuplicatesSheet extends StatefulWidget {
  const GalleryDuplicatesSheet({
    super.key,
    required this.onDuplicatesCleaned,
  });

  final VoidCallback onDuplicatesCleaned;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onDuplicatesCleaned,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GalleryDuplicatesSheet(
        onDuplicatesCleaned: onDuplicatesCleaned,
      ),
    );
  }

  @override
  State<GalleryDuplicatesSheet> createState() => _GalleryDuplicatesSheetState();
}

class _GalleryDuplicatesSheetState extends State<GalleryDuplicatesSheet> {
  List<Map<String, dynamic>> _duplicateGroups = [];
  bool _isLoading = true;
  final Set<String> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    _loadDuplicates();
  }

  Future<void> _loadDuplicates() async {
    setState(() => _isLoading = true);
    final groups = await CloudGalleryService.fetchDuplicates();
    if (mounted) {
      setState(() {
        _duplicateGroups = groups;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDuplicate(String id, int groupIndex) async {
    setState(() => _deletingIds.add(id));
    final success = await CloudGalleryService.deleteAsset(id);
    if (mounted && success) {
      setState(() {
        _deletingIds.remove(id);
        final items = (_duplicateGroups[groupIndex]['items'] as List);
        items.removeWhere((item) => item['id'] == id);
        if (items.length <= 1) {
          _duplicateGroups.removeAt(groupIndex);
        }
      });
      widget.onDuplicatesCleaned();
    } else if (mounted) {
      setState(() => _deletingIds.remove(id));
    }
  }

  Future<void> _cleanAllDuplicatesInGroup(int groupIndex) async {
    final group = _duplicateGroups[groupIndex];
    final items = List<Map<String, dynamic>>.from(group['items'] as List);
    if (items.length <= 1) return;

    // First item is the highest resolution (already sorted by server width DESC)
    final bestId = items.first['id'] as String;
    final duplicatesToDelete = items.skip(1).toList();

    for (final dup in duplicatesToDelete) {
      final dupId = dup['id'] as String;
      setState(() => _deletingIds.add(dupId));
      await CloudGalleryService.deleteAsset(dupId);
    }

    if (mounted) {
      setState(() {
        for (final dup in duplicatesToDelete) {
          _deletingIds.remove(dup['id'] as String);
        }
        _duplicateGroups.removeAt(groupIndex);
      });
      widget.onDuplicatesCleaned();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Removed ${duplicatesToDelete.length} duplicate copy(ies), kept best ($bestId)'),
          backgroundColor: EverforestColors.bg1,
        ),
      );
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                    color: EverforestColors.yellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_delete_rounded,
                      color: EverforestColors.yellow, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Duplicate Cleaner',
                        style: TextStyle(
                          color: EverforestColors.fg,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Perceptual dHash & SHA-256 detection',
                        style: TextStyle(
                            color: EverforestColors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: EverforestColors.grey, size: 20),
                  onPressed: _loadDuplicates,
                ),
              ],
            ),
          ),
          const Divider(color: EverforestColors.bg2, height: 1),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: EverforestColors.yellow),
                  )
                : _duplicateGroups.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline_rounded,
                                color: EverforestColors.green, size: 48),
                            SizedBox(height: 14),
                            Text(
                              'No duplicates found!',
                              style: TextStyle(
                                color: EverforestColors.fg,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Your vault is clean and storage is fully optimized.',
                              style: TextStyle(
                                  color: EverforestColors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _duplicateGroups.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, groupIndex) {
                          final group = _duplicateGroups[groupIndex];
                          final items =
                              (group['items'] as List).cast<Map<String, dynamic>>();

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: EverforestColors.bg1,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.06)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.filter_none_rounded,
                                            color: EverforestColors.yellow,
                                            size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${items.length} copies found',
                                          style: const TextStyle(
                                            color: EverforestColors.fg,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.cleaning_services,
                                          size: 14),
                                      label: const Text('Keep Best'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            EverforestColors.yellow,
                                        foregroundColor: EverforestColors.bg0,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                      onPressed: () =>
                                          _cleanAllDuplicatesInGroup(
                                              groupIndex),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 140,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: items.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 12),
                                    itemBuilder: (context, i) {
                                      final item = items[i];
                                      final itemId = item['id'] as String;
                                      final isBest = i == 0;
                                      final thumbUrl =
                                          '${ApiClient.instance.daemonUrl}/api/v1/gallery/thumbnail?id=$itemId';
                                      final isDeleting =
                                          _deletingIds.contains(itemId);

                                      return Container(
                                        width: 120,
                                        decoration: BoxDecoration(
                                          color: EverforestColors.bg0,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isBest
                                                ? EverforestColors.green
                                                : EverforestColors.bg2,
                                            width: isBest ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Stack(
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Expanded(
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        const BorderRadius
                                                            .vertical(
                                                            top: Radius.circular(
                                                                11)),
                                                    child: ExtendedImage.network(
                                                      thumbUrl,
                                                      fit: BoxFit.cover,
                                                      cache: true,
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(6),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        '${item['width']}x${item['height']}',
                                                        style: const TextStyle(
                                                          color: EverforestColors
                                                              .fg,
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        _formatSize(item[
                                                                'size_bytes'] ??
                                                            0),
                                                        style: const TextStyle(
                                                          color: EverforestColors
                                                              .grey,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (isBest)
                                              Positioned(
                                                top: 6,
                                                left: 6,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 5,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        EverforestColors.green,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: const Text(
                                                    '★ BEST',
                                                    style: TextStyle(
                                                      color: EverforestColors
                                                          .bg0,
                                                      fontSize: 8.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            if (!isBest)
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: IconButton(
                                                  icon: isDeleting
                                                      ? const SizedBox(
                                                          width: 14,
                                                          height: 14,
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color:
                                                                EverforestColors
                                                                    .red,
                                                          ),
                                                        )
                                                      : const Icon(
                                                          Icons
                                                              .delete_outline_rounded,
                                                          color:
                                                              EverforestColors
                                                                  .red,
                                                          size: 18),
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  onPressed: () =>
                                                      _deleteDuplicate(
                                                          itemId, groupIndex),
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
