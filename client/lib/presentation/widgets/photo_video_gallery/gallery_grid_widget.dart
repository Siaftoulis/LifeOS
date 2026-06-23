import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../theme/everforest_colors.dart';
import '../../../core/p2p_transfer_service.dart';
import 'media_viewer.dart';

import 'gallery_item.dart';
import 'gallery_presets.dart';

class GalleryGridWidget extends StatefulWidget {
  const GalleryGridWidget({super.key});

  @override
  State<GalleryGridWidget> createState() => _GalleryGridWidgetState();
}

class _GalleryGridWidgetState extends State<GalleryGridWidget> with SingleTickerProviderStateMixin {
  List<GalleryItem> _items = [];
  bool _isLoading = true;
  String _selectedTab = 'All'; // 'All', 'Photos', 'Videos', 'Tags'
  String _searchQuery = '';
  String _selectedTagFilter = 'All';
  late TabController _tabController;

  final List<String> _tabs = ['All', 'Photos', 'Videos', 'Tags'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabs[_tabController.index];
      });
    });
    _loadMedia();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMedia() async {
    setState(() => _isLoading = true);
    final List<GalleryItem> loaded = [];

    // Scan vault/Media
    try {
      final dir = Directory('vault/Media');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      final files = dir.listSync();
      for (final file in files) {
        if (file is File) {
          final path = file.path;
          final name = file.uri.pathSegments.last;
          
          if (name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png') || name.endsWith('.webp') || name.endsWith('.gif')) {
            final stats = file.statSync();
            loaded.add(GalleryItem(
              id: 'local_${stats.modified.millisecondsSinceEpoch}',
              label: name,
              pathOrUrl: path,
              type: 'photo',
              date: stats.modified,
              tags: ['Local', 'Camera'],
              sizeBytes: stats.size,
              resolution: '1920 x 1080',
              camera: 'Local Camera Roll',
              lens: 'Wide Lens',
              isLocal: true,
            ));
          } else if (name.endsWith('.mp4') || name.endsWith('.mkv') || name.endsWith('.mov')) {
            final stats = file.statSync();
            loaded.add(GalleryItem(
              id: 'local_${stats.modified.millisecondsSinceEpoch}',
              label: name,
              pathOrUrl: path,
              type: 'video',
              date: stats.modified,
              tags: ['Local', 'Videos'],
              sizeBytes: stats.size,
              resolution: '1080p HD',
              camera: 'Local Video Capture',
              lens: 'Standard Lens',
              isLocal: true,
            ));
          }
        }
      }
    } catch (e) {
      debugPrint("Error scanning local gallery media: $e");
    }

    // Add preset items
    final now = DateTime.now();
    for (final p in galleryPresets) {
      final daysAgo = p['daysAgo'] as int;
      final date = now.subtract(Duration(days: daysAgo));
      loaded.add(GalleryItem(
        id: 'preset_${p['label']}',
        label: p['label'],
        pathOrUrl: p['url'],
        type: p['type'],
        date: date,
        tags: List<String>.from(p['tags']),
        sizeBytes: p['size'],
        resolution: p['resolution'],
        camera: p['camera'],
        lens: p['lens'],
        latitude: p['lat'],
        longitude: p['lng'],
        isLocal: false,
      ));
    }

    // Sort by date descending
    loaded.sort((a, b) => b.date.compareTo(a.date));

    setState(() {
      _items = loaded;
      _isLoading = false;
    });
  }

  Future<void> _captureMockPhoto() async {
    setState(() => _isLoading = true);
    try {
      final dir = Directory('vault/Media');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/camera_roll_$timestamp.jpg');
      
      final response = await http.get(Uri.parse('https://picsum.photos/1200/800?random=$timestamp'));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mock photo captured and saved to vault/Media!'),
            backgroundColor: EverforestColors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Capture mock photo failed: $e");
    }
    _loadMedia();
  }

  // Helper to group items by Date string
  Map<String, List<GalleryItem>> _groupItems(List<GalleryItem> items) {
    final Map<String, List<GalleryItem>> grouped = {};
    final now = DateTime.now();
    final todayStr = _formatDate(now);
    final yesterdayStr = _formatDate(now.subtract(const Duration(days: 1)));

    for (final item in items) {
      String groupKey = _formatDate(item.date);
      if (groupKey == todayStr) {
        groupKey = 'Today';
      } else if (groupKey == yesterdayStr) {
        groupKey = 'Yesterday';
      }
      if (!grouped.containsKey(groupKey)) {
        grouped[groupKey] = [];
      }
      grouped[groupKey]!.add(item);
    }
    return grouped;
  }

  String _formatDate(DateTime dt) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  List<GalleryItem> _getFilteredItems() {
    List<GalleryItem> filtered = List.from(_items);

    // Apply Search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((item) =>
              item.label.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              item.tags.any((t) => t.toLowerCase().contains(_searchQuery.toLowerCase())))
          .toList();
    }

    // Apply tab categorization
    if (_selectedTab == 'Photos') {
      filtered = filtered.where((item) => item.type == 'photo').toList();
    } else if (_selectedTab == 'Videos') {
      filtered = filtered.where((item) => item.type == 'video').toList();
    } else if (_selectedTab == 'Tags') {
      if (_selectedTagFilter != 'All') {
        filtered = filtered.where((item) => item.tags.contains(_selectedTagFilter)).toList();
      }
    }

    return filtered;
  }

  Set<String> _getAllTags() {
    final Set<String> tags = {'All'};
    for (final item in _items) {
      tags.addAll(item.tags);
    }
    return tags;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredItems();
    final grouped = _groupItems(filtered);
    final allTags = _getAllTags();

    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg1,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: EverforestColors.bg0,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            style: const TextStyle(color: EverforestColors.fg),
            decoration: const InputDecoration(
              hintText: 'Search photos & tags...',
              hintStyle: TextStyle(color: EverforestColors.grey),
              prefixIcon: Icon(Icons.search, color: EverforestColors.grey, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: EverforestColors.green,
          labelColor: EverforestColors.fg,
          unselectedLabelColor: EverforestColors.grey,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: EverforestColors.green))
          : Column(
              children: [
                // Tag selector row if we are on the Tags tab
                if (_selectedTab == 'Tags')
                  Container(
                    height: 48,
                    color: EverforestColors.bg1,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      children: allTags.map((tag) {
                        final isSel = _selectedTagFilter == tag;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTagFilter = tag;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSel ? EverforestColors.green : EverforestColors.bg2,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: isSel ? EverforestColors.bg0 : EverforestColors.fg,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'No media items found',
                            style: TextStyle(color: EverforestColors.grey, fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: grouped.keys.length,
                          itemBuilder: (context, groupIdx) {
                            final dateKey = grouped.keys.elementAt(groupIdx);
                            final groupItems = grouped[dateKey]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
                                  child: Text(
                                    dateKey,
                                    style: const TextStyle(
                                      color: EverforestColors.fg,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 140,
                                    crossAxisSpacing: 6,
                                    mainAxisSpacing: 6,
                                    childAspectRatio: 1,
                                  ),
                                  itemCount: groupItems.length,
                                  itemBuilder: (context, itemIdx) {
                                    final item = groupItems[itemIdx];
                                    final isVideo = item.type == 'video';

                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => MediaViewer(
                                              items: groupItems,
                                              initialIndex: itemIdx,
                                              onDataChanged: _loadMedia,
                                            ),
                                          ),
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            // Image loader
                                            item.isLocal
                                                ? Image.file(
                                                    File(item.pathOrUrl),
                                                    fit: BoxFit.cover,
                                                  )
                                                : Image.network(
                                                    item.pathOrUrl,
                                                    fit: BoxFit.cover,
                                                    loadingBuilder: (_, child, prog) => prog == null
                                                        ? child
                                                        : Container(
                                                            color: EverforestColors.bg2,
                                                            child: const Center(
                                                              child: SizedBox(
                                                                width: 20,
                                                                height: 20,
                                                                child: CircularProgressIndicator(
                                                                  color: EverforestColors.green,
                                                                  strokeWidth: 2,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                  ),
                                            // Gradient Overlay
                                            Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    EverforestColors.bg0.withOpacity(0.65),
                                                    Colors.transparent,
                                                  ],
                                                  begin: Alignment.bottomCenter,
                                                  end: Alignment.topCenter,
                                                ),
                                              ),
                                            ),
                                            if (isVideo)
                                              const Center(
                                                child: Icon(
                                                  Icons.play_circle_fill,
                                                  color: Colors.white70,
                                                  size: 36,
                                                ),
                                              ),
                                            if (item.isLocal)
                                              const Positioned(
                                                top: 6,
                                                left: 6,
                                                child: Icon(
                                                  Icons.sd_card,
                                                  color: EverforestColors.green,
                                                  size: 16,
                                                ),
                                              ),
                                            Positioned(
                                              bottom: 6,
                                              left: 8,
                                              right: 8,
                                              child: Text(
                                                item.label,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _captureMockPhoto,
        backgroundColor: EverforestColors.green,
        child: const Icon(Icons.add_a_photo, color: EverforestColors.bg0),
      ),
    );
  }
}
