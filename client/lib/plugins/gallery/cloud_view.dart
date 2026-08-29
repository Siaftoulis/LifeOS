import 'package:flutter/material.dart';
import '../../core/cloud_gallery_service.dart';
import '../../core/gallery_sync_engine.dart';
import '../../presentation/widgets/media_hub/photo_video_gallery/gallery_item.dart';
import '../../theme/everforest_colors.dart';
import 'gallery_duplicates_sheet.dart';
import 'gallery_smart_albums_view.dart';
import 'gallery_timeline_view.dart';

class CloudView extends StatefulWidget {
  const CloudView({super.key});

  @override
  State<CloudView> createState() => _CloudViewState();
}

class _CloudViewState extends State<CloudView> {
  final GallerySyncEngine _syncEngine = GallerySyncEngine.instance;
  final ScrollController _scrollController = ScrollController();

  final List<GalleryItem> _cloudItems = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  static const int _pageSize = 60;

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
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
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
      final items = await CloudGalleryService.fetchCloudAssets(
          limit: _pageSize, offset: _offset);
      if (mounted) {
        setState(() {
          if (items.length < _pageSize) {
            _hasMore = false;
          }
          _cloudItems.addAll(items);
          _offset += items.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore) return;

    setState(() => _isLoadingMore = true);
    try {
      final items = await CloudGalleryService.fetchCloudAssets(
          limit: _pageSize, offset: _offset);
      if (mounted) {
        setState(() {
          if (items.length < _pageSize) {
            _hasMore = false;
          }
          _cloudItems.addAll(items);
          _offset += items.length;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
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
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: EverforestColors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.cloud_sync_rounded,
                    color: EverforestColors.green, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Cloud Gallery Vault',
                style: TextStyle(
                  color: EverforestColors.fg,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            indicatorColor: EverforestColors.green,
            indicatorWeight: 3,
            labelColor: EverforestColors.green,
            unselectedLabelColor: EverforestColors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
            tabs: [
              Tab(
                icon: Icon(Icons.photo_library_rounded, size: 18),
                text: 'Timeline',
              ),
              Tab(
                icon: Icon(Icons.folder_special_rounded, size: 18),
                text: 'Smart Albums',
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.auto_delete_rounded,
                  color: EverforestColors.yellow, size: 22),
              tooltip: 'Duplicate Cleaner',
              onPressed: () => GalleryDuplicatesSheet.show(
                context,
                onDuplicatesCleaned: _refreshData,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: EverforestColors.grey, size: 22),
              tooltip: 'Refresh Gallery',
              onPressed: _refreshData,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: TabBarView(
          children: [
            GalleryTimelineView(
              items: _cloudItems,
              isLoading: _isLoading,
              isLoadingMore: _isLoadingMore,
              hasMore: _hasMore,
              onRefresh: _refreshData,
              scrollController: _scrollController,
            ),
            GallerySmartAlbumsView(
              items: _cloudItems,
            ),
          ],
        ),
      ),
    );
  }
}
