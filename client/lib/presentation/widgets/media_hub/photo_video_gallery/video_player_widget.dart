import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../theme/everforest_colors.dart';
import 'gallery_item.dart';

class VideoPlayerWidget extends StatefulWidget {
  final GalleryItem item;
  final bool isImmersive;
  final bool isActive;
  final VoidCallback onTap;

  const VideoPlayerWidget({
    super.key, 
    required this.item,
    required this.isImmersive,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pause when the page is swiped away so audio doesn't keep playing
    // in the background.
    if (widget.isActive != oldWidget.isActive && !widget.isActive) {
      _controller?.pause();
    }
  }

  Future<void> _initPlayer() async {
    File? file;
    if (widget.item.assetEntity != null) {
      file = await widget.item.assetEntity!.file;
    } else if (widget.item.pathOrUrl.isNotEmpty) {
      file = File(widget.item.pathOrUrl);
    }

    if (file != null && await file.exists()) {
      _controller = VideoPlayerController.file(file);
      try {
        await _controller!.initialize();
      } catch (_) {
        if (mounted) setState(() => _loadFailed = true);
        return;
      }
      if (!mounted) return;
      setState(() {});

      // Only rebuild when play state flips; the progress bar rebuilds itself
      // via AnimatedBuilder so we avoid rebuilding the whole page every frame.
      _controller!.addListener(() {
        final playing = _controller!.value.isPlaying;
        if (playing != _isPlaying && mounted) {
          setState(() => _isPlaying = playing);
        }
      });
    } else if (mounted) {
      setState(() => _loadFailed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller == null) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      if (widget.isImmersive) widget.onTap(); // show controls if paused while immersive
    } else {
      _controller!.play();
      if (!widget.isImmersive) widget.onTap(); // hide controls when playing starts
    }
  }

  bool _isScrubbing = false;
  bool get _isActive => _isPlaying || _isScrubbing;

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_controller == null) return;
    setState(() => _isScrubbing = true);
    _controller!.pause();
    if (widget.isImmersive) widget.onTap();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_controller == null) return;
    final width = MediaQuery.of(context).size.width;
    final dx = details.primaryDelta ?? 0;
    
    // Adjust sensitivity: full screen width = full video length
    final duration = _controller!.value.duration.inMilliseconds;
    final position = _controller!.value.position.inMilliseconds;
    
    final deltaMs = (dx / width) * duration;
    final newPositionMs = (position + deltaMs).clamp(0, duration);
    
    _controller!.seekTo(Duration(milliseconds: newPositionMs.toInt()));
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    setState(() => _isScrubbing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadFailed) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, color: EverforestColors.grey, size: 48),
            SizedBox(height: 8),
            Text(
              'Video unavailable',
              style: TextStyle(color: EverforestColors.grey),
            ),
          ],
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: EverforestColors.green));
    }

    final showControls = !widget.isImmersive || !_isPlaying;
    // When immersive is false, the bottom actions bar is visible (~80px tall), so we shift the progress bar up.
    // When immersive is true, it is hidden, so we can place it at the very bottom edge.
    final bottomPadding = widget.isImmersive ? 0.0 : 90.0;

    return GestureDetector(
      onTap: widget.onTap,
      onHorizontalDragStart: _isActive ? _onHorizontalDragStart : null,
      onHorizontalDragUpdate: _isActive ? _onHorizontalDragUpdate : null,
      onHorizontalDragEnd: _isActive ? _onHorizontalDragEnd : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
          
          // Play/Stop Button
          if (showControls)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                iconSize: 56,
                color: Colors.white,
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: _togglePlay,
              ),
            ),
            
          // Timeline Scrubber
          if (_isActive)
            Positioned(
              bottom: bottomPadding,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _controller!,
                builder: (context, _) {
                  final pos = _controller!.value.position.inMilliseconds.toDouble();
                  final dur = _controller!.value.duration.inMilliseconds.toDouble();
                  final progress = dur > 0 ? pos / dur : 0.0;
                  return Container(
                    height: 4,
                    color: Colors.black26,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        color: EverforestColors.green,
                      ),
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
