import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../api_client.dart';
import '../../../../core/domain_repositories.dart';
import '../../../../theme/everforest_colors.dart';

class YoutubePlayerScreen extends StatefulWidget {
  final YoutubeVideo video;
  const YoutubePlayerScreen({super.key, required this.video});

  @override
  State<YoutubePlayerScreen> createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
  VideoPlayerController? _controller;
  bool _resolving = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _resolveAndPlay();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _resolveAndPlay() async {
    final meta = await YoutubeRepository.instance.streams(widget.video.id);
    if (!mounted) return;

    final url = meta.live
        ? meta.hls // HLS manifest, played directly (only live when bridge gave us hls)
        : '${ApiClient.instance.daemonUrl}/api/v1/youtube/stream?id=${widget.video.id}';
    if (url.isEmpty) {
      setState(() {
        _resolving = false;
        _failed = true;
      });
      return;
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _resolving = false;
      });
      controller.play();
      controller.setLooping(true);
    } catch (_) {
      controller.dispose();
      if (mounted) {
        setState(() {
          _resolving = false;
          _failed = true;
        });
      }
    }
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    c.value.isPlaying ? c.pause() : c.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg1,
        iconTheme: const IconThemeData(color: EverforestColors.fg),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.video.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.bold)),
            if (widget.video.live)
              const Text('LIVE', style: TextStyle(color: EverforestColors.red, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Center(
        child: _resolving
            ? const CircularProgressIndicator(color: EverforestColors.green)
            : _failed
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image_outlined, color: EverforestColors.grey, size: 48),
                      SizedBox(height: 8),
                      Text('Could not play this video', style: TextStyle(color: EverforestColors.grey)),
                    ],
                  )
                : _controller == null || !_controller!.value.isInitialized
                    ? const CircularProgressIndicator(color: EverforestColors.green)
                    : GestureDetector(
                        onTap: _togglePlay,
                        child: AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        ),
                      ),
      ),
    );
  }
}