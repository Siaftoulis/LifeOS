import 'package:flutter/material.dart';
import '../../theme/everforest_colors.dart';
import '../../core/cloud_gallery_service.dart';
import '../../core/gallery_sync_engine.dart';
import '../../presentation/widgets/media_hub/photo_video_gallery/gallery_item.dart';
import '../../presentation/widgets/media_hub/photo_video_gallery/aves_viewer_screen.dart';
import '../../api_client.dart';
import 'package:extended_image/extended_image.dart';

class CloudView extends StatefulWidget {
  const CloudView({super.key});

  @override
  State<CloudView> createState() => _CloudViewState();
}

class _CloudViewState extends State<CloudView> {
  final GallerySyncEngine _syncEngine = GallerySyncEngine.instance;
  final ScrollController _scrollController = ScrollController();
  
  List<GalleryItem> _cloudItems = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  static const int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _fetchCloudData();
    _syncEngine.isSyncing.addListener(_onSyncStateChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _syncEngine.isSyncing.removeListener(_onSyncStateChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSyncStateChanged() {
    if (!_syncEngine.isSyncing.value) {
      _refreshData();
    }
    setState(() {});
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _cloudItems.clear();
      _offset = 0;
      _hasMore = true;
      _isLoading = true;
    });
    await _fetchCloudData();
  }

  Future<void> _fetchCloudData() async {
    try {
      final items = await CloudGalleryService.fetchCloudAssets(limit: _pageSize, offset: _offset);
      setState(() {
        if (items.length < _pageSize) {
          _hasMore = false;
        }
        _cloudItems.addAll(items);
        _offset += items.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    
    setState(() => _isLoadingMore = true);
    try {
      final items = await CloudGalleryService.fetchCloudAssets(limit: _pageSize, offset: _offset);
      setState(() {
        if (items.length < _pageSize) {
          _hasMore = false;
        }
        _cloudItems.addAll(items);
        _offset += items.length;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: EverforestColors.bg0,
        appBar: AppBar(
          backgroundColor: EverforestColors.bg0,
          elevation: 0,
          title: const Text('Cloud Sync', style: TextStyle(color: EverforestColors.fg)),
          bottom: const TabBar(
            indicatorColor: EverforestColors.green,
            labelColor: EverforestColors.green,
            unselectedLabelColor: EverforestColors.grey,
            tabs: [
              Tab(text: 'Timeline'),
              Tab(text: 'Folders'),
            ],
          ),
          actions: [
            ValueListenableBuilder<bool>(
              valueListenable: _syncEngine.isSyncing,
              builder: (context, isSyncing, child) {
                if (isSyncing) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Center(
                      child: ValueListenableBuilder<int>(
                        valueListenable: _syncEngine.syncedCount,
                        builder: (context, synced, child) {
                          return Text(
                            '$synced / ${_syncEngine.totalToSync.value}',
                            style: const TextStyle(color: EverforestColors.green, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                    ),
                  );
                }
                return IconButton(
                  icon: const Icon(Icons.sync, color: EverforestColors.green),
                  onPressed: () {
                    _syncEngine.startSync();
                  },
                );
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildTimelineView(),
            const Center(child: Text('Folder View (By User/Device)', style: TextStyle(color: EverforestColors.fg))),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineView() {
    if (_isLoading && _cloudItems.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: EverforestColors.green));
    }
    if (_cloudItems.isEmpty) {
      return const Center(child: Text('No media in the cloud.', style: TextStyle(color: EverforestColors.fg)));
    }
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _cloudItems.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _cloudItems.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: EverforestColors.green, strokeWidth: 2),
            ),
          );
        }
        final item = _cloudItems[index];
        return GestureDetector(
          onTap: () => Navigator.push(context, PageRouteBuilder(
            pageBuilder: (_, __, ___) => AvesViewerScreen(
              items: _cloudItems,
              initialIndex: index,
            ),
          )),
          child: Hero(
            tag: 'gallery_hero_${item.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: ExtendedImage.network(
                '${ApiClient.instance.daemonUrl}/api/v1/gallery/thumbnail?id=${item.id}',
                fit: BoxFit.cover,
                cache: true,
                loadStateChanged: (ExtendedImageState state) {
                  switch (state.extendedImageLoadState) {
                    case LoadState.loading:
                      return Container(color: EverforestColors.bg1);
                    case LoadState.failed:
                      return Container(
                        color: EverforestColors.bg1,
                        child: const Icon(Icons.broken_image, color: EverforestColors.grey),
                      );
                    case LoadState.completed:
                      return state.completedWidget;
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
