import 'dart:io';
import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../core/p2p_transfer_service.dart';
import '../../../core/p2p_models.dart';
import 'gallery_item.dart';
import 'metadata_sheet.dart';
import 'peer_share_sheet.dart';

class MediaViewer extends StatefulWidget {
  final List<GalleryItem> items;
  final int initialIndex;
  final VoidCallback onDataChanged;

  const MediaViewer({
    super.key,
    required this.items,
    required this.initialIndex,
    required this.onDataChanged,
  });

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showProgressOverlay(P2PProgress? initialProgress) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ValueListenableBuilder<P2PProgress?>(
          valueListenable: P2PTransferService.instance.progressNotifier,
          builder: (context, progress, _) {
            final displayProg = progress ?? initialProgress;
            if (displayProg == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.canPop(context)) Navigator.pop(context);
              });
              return const SizedBox();
            }

            return AlertDialog(
              backgroundColor: EverforestColors.bg1,
              title: Text(
                displayProg.isSender ? 'Sending File' : 'Receiving File',
                style: const TextStyle(color: EverforestColors.fg),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    displayProg.fileName,
                    style: const TextStyle(color: EverforestColors.fg, fontSize: 13, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: displayProg.percent,
                    color: EverforestColors.green,
                    backgroundColor: EverforestColors.bg2,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(displayProg.percent * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: EverforestColors.fg, fontSize: 11),
                      ),
                      Text(
                        '${displayProg.speedMBs.toStringAsFixed(2)} MB/s',
                        style: const TextStyle(color: EverforestColors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showModalBottomSheet(
              context: context,
              backgroundColor: EverforestColors.bg1,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (ctx) => SizedBox(
                height: 480,
                child: MetadataSheet(item: widget.items[_currentIndex]),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => showModalBottomSheet(
              context: context,
              backgroundColor: EverforestColors.bg1,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (ctx) => SizedBox(
                height: 300,
                child: PeerShareSheet(
                  item: widget.items[_currentIndex],
                  onStartProgress: (prog) => _showProgressOverlay(prog),
                  onComplete: widget.onDataChanged,
                ),
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 300) {
            Navigator.pop(context);
          }
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.items.length,
          onPageChanged: (idx) {
            setState(() {
              _currentIndex = idx;
            });
          },
          itemBuilder: (context, idx) {
            final item = widget.items[idx];

            return InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Center(
                child: Hero(
                  tag: item.id,
                  child: item.isLocal
                      ? Image.file(
                          File(item.pathOrUrl),
                          fit: BoxFit.contain,
                        )
                      : Image.network(
                          item.pathOrUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (_, child, prog) => prog == null
                              ? child
                              : const CircularProgressIndicator(color: EverforestColors.green),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
