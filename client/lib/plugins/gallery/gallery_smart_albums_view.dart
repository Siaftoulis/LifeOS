import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../presentation/widgets/media_hub/photo_video_gallery/aves_viewer_screen.dart';
import '../../presentation/widgets/media_hub/photo_video_gallery/gallery_item.dart';
import '../../theme/everforest_colors.dart';

class GallerySmartAlbumsView extends StatefulWidget {
  const GallerySmartAlbumsView({
    super.key,
    required this.items,
  });

  final List<GalleryItem> items;

  @override
  State<GallerySmartAlbumsView> createState() => _GallerySmartAlbumsViewState();
}

class _GallerySmartAlbumsViewState extends State<GallerySmartAlbumsView> {
  String? _selectedFilterTitle;
  List<GalleryItem>? _filteredItems;

  void _filterByPredicate(String title, bool Function(GalleryItem) predicate) {
    setState(() {
      _selectedFilterTitle = title;
      _filteredItems = widget.items.where(predicate).toList();
    });
  }

  void _clearFilter() {
    setState(() {
      _selectedFilterTitle = null;
      _filteredItems = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedFilterTitle != null && _filteredItems != null) {
      return _buildFilteredView();
    }

    final videos = widget.items.where((i) => i.type == 'video').toList();
    final photos = widget.items.where((i) => i.type == 'photo').toList();
    final screenshots = widget.items.where((i) =>
        i.label.toLowerCase().contains('screenshot') ||
        i.camera.toLowerCase().contains('screenshot')).toList();
    final camera = widget.items.where((i) => !screenshots.contains(i)).toList();

    // Extract all unique tags
    final Map<String, int> tagCounts = {};
    for (final item in widget.items) {
      for (final tag in item.tags) {
        if (tag.isNotEmpty) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        const Text(
          'SMART ALBUMS',
          style: TextStyle(
            color: EverforestColors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),

        // Grid of Main Albums
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildAlbumCard(
              title: 'Camera Roll',
              count: camera.length,
              icon: Icons.camera_alt_rounded,
              color: EverforestColors.green,
              coverItem: camera.isNotEmpty ? camera.first : null,
              onTap: () => _filterByPredicate(
                  'Camera Roll', (i) => camera.contains(i)),
            ),
            _buildAlbumCard(
              title: 'Videos',
              count: videos.length,
              icon: Icons.videocam_rounded,
              color: EverforestColors.purple,
              coverItem: videos.isNotEmpty ? videos.first : null,
              onTap: () =>
                  _filterByPredicate('Videos', (i) => i.type == 'video'),
            ),
            _buildAlbumCard(
              title: 'Screenshots',
              count: screenshots.length,
              icon: Icons.phone_android_rounded,
              color: EverforestColors.blue,
              coverItem: screenshots.isNotEmpty ? screenshots.first : null,
              onTap: () => _filterByPredicate(
                  'Screenshots', (i) => screenshots.contains(i)),
            ),
            _buildAlbumCard(
              title: 'All Photos',
              count: photos.length,
              icon: Icons.photo_library_rounded,
              color: EverforestColors.yellow,
              coverItem: photos.isNotEmpty ? photos.first : null,
              onTap: () =>
                  _filterByPredicate('All Photos', (i) => i.type == 'photo'),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Semantic AI Tags Section
        if (tagCounts.isNotEmpty) ...[
          const Text(
            'AI SEMANTIC TAGS',
            style: TextStyle(
              color: EverforestColors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tagCounts.entries.map((e) {
              final tag = e.key;
              final count = e.value;

              return InkWell(
                onTap: () => _filterByPredicate(
                    'Tag: #$tag', (i) => i.tags.contains(tag)),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: EverforestColors.bg1,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: EverforestColors.green.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tag_rounded,
                          color: EverforestColors.green, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        tag,
                        style: const TextStyle(
                          color: EverforestColors.fg,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: EverforestColors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: EverforestColors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
        ],
      ],
    );
  }

  Widget _buildAlbumCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required GalleryItem? coverItem,
    required VoidCallback onTap,
  }) {
    final thumbUrl = coverItem != null
        ? '${ApiClient.instance.daemonUrl}/api/v1/gallery/thumbnail?id=${coverItem.id}'
        : '';

    return InkWell(
      onTap: count > 0 ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: EverforestColors.bg1,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbUrl.isNotEmpty)
              Opacity(
                opacity: 0.25,
                child: ExtendedImage.network(
                  thumbUrl,
                  fit: BoxFit.cover,
                  cache: true,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: EverforestColors.fg,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count items',
                        style: const TextStyle(
                          color: EverforestColors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredView() {
    final items = _filteredItems ?? [];
    final isWide = MediaQuery.of(context).size.width >= 700;
    final crossAxisCount = isWide ? 5 : 3;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: EverforestColors.fg),
                onPressed: _clearFilter,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedFilterTitle ?? 'Album',
                  style: const TextStyle(
                    color: EverforestColors.fg,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${items.length} items',
                style:
                    const TextStyle(color: EverforestColors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
        const Divider(color: EverforestColors.bg2, height: 1),
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Text('No items in this album',
                      style: TextStyle(color: EverforestColors.grey)),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final thumbUrl =
                        '${ApiClient.instance.daemonUrl}/api/v1/gallery/thumbnail?id=${item.id}';

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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ExtendedImage.network(
                          thumbUrl,
                          fit: BoxFit.cover,
                          cache: true,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
