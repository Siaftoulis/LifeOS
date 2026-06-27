import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../theme/everforest_colors.dart';
import 'gallery_item.dart';

class VideoPlayerWidget extends StatefulWidget {
  final GalleryItem item;
  final bool isImmersive;
  final VoidCallback onTap;

  const VideoPlayerWidget({
    super.key, 
    required this.item,
    required this.isImmersive,
    required this.onTap,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
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
      await _controller!.initialize();
      setState(() {});
      
      _controller!.addListener(() {
        if (_controller!.value.isPlaying != _isPlaying) {
          setState(() {
            _isPlaying = _controller!.value.isPlaying;
          });
        }
        // Force rebuild for progress bar
        setState(() {});
      });
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
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: EverforestColors.green));
    }

    final pos = _controller!.value.position.inMilliseconds.toDouble();
    final dur = _controller!.value.duration.inMilliseconds.toDouble();
    final progress = dur > 0 ? pos / dur : 0.0;

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
                color: Colors.black.withOpacity(0.4),
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
              child: Container(
                height: 4,
                color: Colors.black26,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    color: EverforestColors.green,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
