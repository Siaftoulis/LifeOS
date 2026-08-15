import 'package:flutter/material.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../../core/cloud_gallery_service.dart';
import '../../core/device_gallery_service.dart';
import '../../core/smart_picker_service.dart';
import '../../theme/everforest_colors.dart';
import '../../presentation/widgets/media_hub/photo_video_gallery/gallery_item.dart';

/// Smart picker screen: analyze local photos (metadata -> server analysis ->
/// suggested title/tags) and apply. Also lists cloud duplicates.
class SmartPickerView extends StatefulWidget {
  const SmartPickerView({super.key});

  @override
  State<SmartPickerView> createState() => _SmartPickerViewState();
}

class _SmartPickerViewState extends State<SmartPickerView> {
  final DeviceGalleryService _galleryService = DeviceGalleryService();
  List<GalleryItem> _items = [];
  bool _loadingItems = true;
  final Map<String, SmartPickResult> _results = {}; // item id -> result
  final Set<String> _picking = {};
  final Set<String> _applied = {};
  List<Map<String, dynamic>> _duplicates = [];
  bool _loadingDuplicates = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadDuplicates();
  }

  Future<void> _loadItems() async {
    final items = await _galleryService.fetchMediaPage(page: 0);
    if (mounted) setState(() {
      _items = items;
      _loadingItems = false;
    });
  }

  Future<void> _loadDuplicates() async {
    final dups = await CloudGalleryService.fetchDuplicates();
    if (mounted) setState(() {
      _duplicates = dups;
      _loadingDuplicates = false;
    });
  }

  Future<void> _pick(GalleryItem item) async {
    setState(() => _picking.add(item.id));
    final result = await SmartPickerService.instance.pick(item);
    if (mounted) {
      setState(() {
        _picking.remove(item.id);
        if (result != null) _results[item.id] = result;
      });
    }
  }

  Future<void> _apply(GalleryItem item) async {
    final result = _results[item.id];
    if (result == null) return;
    setState(() => _picking.add(item.id));

    // Upload to cloud first (server dedupes + stores analysis), then apply
    // local tags so search works offline too.
    if (item.assetEntity != null) {
      await CloudGalleryService.uploadAsset(item);
    }
    final ok = await SmartPickerService.instance.apply(result);
    if (mounted) {
      setState(() {
        _picking.remove(item.id);
        if (ok) {
          _applied.add(item.id);
          _results.remove(item.id);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Applied: ${result.analysis.title}'
            : 'Failed to apply smart metadata'),
      ));
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
          title: const Text('Smart Picker', style: TextStyle(color: EverforestColors.fg)),
          bottom: const TabBar(
            indicatorColor: EverforestColors.green,
            labelColor: EverforestColors.green,
            unselectedLabelColor: EverforestColors.grey,
            tabs: [
              Tab(text: 'Photos'),
              Tab(text: 'Duplicates'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildItemsTab(), _buildDuplicatesTab()],
        ),
      ),
    );
  }

  Widget _buildItemsTab() {
    if (_loadingItems) {
      return const Center(child: CircularProgressIndicator(color: EverforestColors.green));
    }
    if (_items.isEmpty) {
      return const Center(child: Text('No photos found.', style: TextStyle(color: EverforestColors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final result = _results[item.id];
        return Card(
          color: EverforestColors.bg1,
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: item.assetEntity != null
                        ? AssetEntityImage(item.assetEntity!, isOriginal: false, fit: BoxFit.cover)
                        : Container(color: EverforestColors.bg2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result?.analysis.title ?? item.label,
                        style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (result != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${result.analysis.source} · ${result.analysis.width}x${result.analysis.height}'
                          '${result.place.isNotEmpty ? ' · ${result.place}' : ''}',
                          style: const TextStyle(color: EverforestColors.grey, fontSize: 11),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: result.analysis.tags
                              .map((t) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: EverforestColors.bg2,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(t, style: const TextStyle(color: EverforestColors.green, fontSize: 10)),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (_picking.contains(item.id))
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: EverforestColors.green),
                    ),
                  )
                else if (_applied.contains(item.id))
                  const Icon(Icons.check_circle, color: EverforestColors.green)
                else if (result == null)
                  IconButton(
                    icon: const Icon(Icons.auto_awesome, color: EverforestColors.green),
                    tooltip: 'Smart pick',
                    onPressed: () => _pick(item),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.check, color: EverforestColors.green),
                    tooltip: 'Apply',
                    onPressed: () => _apply(item),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDuplicatesTab() {
    if (_loadingDuplicates) {
      return const Center(child: CircularProgressIndicator(color: EverforestColors.green));
    }
    if (_duplicates.isEmpty) {
      return const Center(
        child: Text('No duplicates found.', style: TextStyle(color: EverforestColors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _duplicates.length,
      itemBuilder: (context, index) {
        final group = _duplicates[index];
        final items = (group['items'] as List).cast<Map<String, dynamic>>();
        final best = items.reduce((a, b) =>
            ((a['width'] ?? 0) * (a['height'] ?? 0)) >= ((b['width'] ?? 0) * (b['height'] ?? 0)) ? a : b);
        return Card(
          color: EverforestColors.bg1,
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${items.length} copies · ${group['hash']?.toString().substring(0, 8)}',
                    style: const TextStyle(color: EverforestColors.grey, fontSize: 11)),
                const SizedBox(height: 6),
                for (final it in items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(it == best ? Icons.star : Icons.cloud_outlined,
                            color: it == best ? EverforestColors.green : EverforestColors.grey, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${it['filename']} · ${it['width']}x${it['height']} · ${it['size_bytes']} bytes',
                            style: TextStyle(
                              color: it == best ? EverforestColors.fg : EverforestColors.grey,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                const Text(
                  'Highest resolution copy is kept automatically on upload.',
                  style: TextStyle(color: EverforestColors.green, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
