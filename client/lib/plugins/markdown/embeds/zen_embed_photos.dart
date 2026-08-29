import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../../../theme/everforest_colors.dart';
import '../../../api_client.dart';
import '../../../core/device_gallery_service.dart';
import '../../../presentation/widgets/media_hub/photo_video_gallery/gallery_item.dart';
import '../../../presentation/widgets/media_hub/photo_video_gallery/aves_viewer_screen.dart';

class PhotosEmbedPreview extends StatefulWidget {
  const PhotosEmbedPreview({super.key, this.ref});

  /// Single-photo embed reference (gallery asset id from the daemon).
  final String? ref;

  @override
  State<PhotosEmbedPreview> createState() => _PhotosEmbedPreviewState();
}

class _PhotosEmbedPreviewState extends State<PhotosEmbedPreview> {
  final DeviceGalleryService _service = DeviceGalleryService();
  List<GalleryItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.ref != null && widget.ref!.isNotEmpty) return;
    _load();
  }

  Future<void> _load() async {
    var granted = await _service.requestPermission();
    var items = <GalleryItem>[];
    if (granted) {
      try {
        items = await _service.fetchMediaPage(page: 0);
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ref != null && widget.ref!.isNotEmpty) {
      return _SinglePhotoEmbed(ref: widget.ref!);
    }
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: EverforestColors.green),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text(
          'No photos yet — tap to open the gallery',
          style: TextStyle(color: EverforestColors.grey),
        ),
      );
    }
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: math.min(12, _items.length),
      itemBuilder: (context, index) {
        final item = _items[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 300),
              pageBuilder: (_, __, ___) =>
                  AvesViewerScreen(items: _items, initialIndex: index),
            ),
          ),
          child: _thumbnail(item),
        );
      },
    );
  }

  Widget _thumbnail(GalleryItem item) {
    final Widget image = item.assetEntity != null
        ? AssetEntityImage(
            item.assetEntity!,
            isOriginal: false,
            thumbnailSize: const ThumbnailSize.square(200),
            fit: BoxFit.cover,
          )
        : Image.file(
            File(item.pathOrUrl),
            fit: BoxFit.cover,
            cacheWidth: 200,
          );
    return ClipRRect(borderRadius: BorderRadius.circular(4), child: image);
  }
}

/// Renders one gallery asset from the daemon as a metadata card with its thumbnail.
class _SinglePhotoEmbed extends StatefulWidget {
  const _SinglePhotoEmbed({required this.ref});

  final String ref;

  @override
  State<_SinglePhotoEmbed> createState() => _SinglePhotoEmbedState();
}

class _SinglePhotoEmbedState extends State<_SinglePhotoEmbed> {
  Map<String, dynamic>? _asset;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.instance.getDaemon(
        '/api/v1/gallery/asset?id=${Uri.encodeQueryComponent(widget.ref)}',
      );
      if (mounted) {
        setState(() =>
            _asset = res is Map ? Map<String, dynamic>.from(res) : null);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Center(
        child: Text(
          'Photo not found — tap to open the gallery',
          style: TextStyle(color: EverforestColors.grey),
        ),
      );
    }
    final a = _asset;
    if (a == null) {
      return const Center(
        child: CircularProgressIndicator(color: EverforestColors.green),
      );
    }

    final thumbUrl =
        '${ApiClient.instance.daemonUrl}/api/v1/gallery/thumbnail?id='
        '${Uri.encodeQueryComponent(widget.ref)}';
    final tags = (a['tags'] as List?)?.cast<String>() ?? [];
    final date = (a['created_at'] as String? ?? '').split('T').first;

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EverforestColors.bg2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              thumbUrl,
              width: 68,
              height: 68,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 68,
                height: 68,
                color: EverforestColors.bg1,
                child: const Icon(Icons.image_outlined, color: EverforestColors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  (a['title']?.toString() ?? '').isNotEmpty
                      ? a['title'].toString()
                      : a['filename']?.toString() ?? 'Unknown Photo',
                  style: const TextStyle(
                    color: EverforestColors.fg,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${a['source'] ?? ''} • ${a['width'] ?? 0}×${a['height'] ?? 0}',
                  style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(color: EverforestColors.grey, fontSize: 11),
                  ),
                ],
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    tags.take(3).join(' · '),
                    style: const TextStyle(
                      color: EverforestColors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
