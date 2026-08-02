import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../theme/everforest_colors.dart';
import '../../../../core/general_engine/engine_repository.dart';
import '../../../../core/general_engine/general_engine_client.dart';
class MusicDashboardWidget extends StatefulWidget {
  const MusicDashboardWidget({super.key});

  @override
  State<MusicDashboardWidget> createState() => _MusicDashboardWidgetState();
}

class _MusicDashboardWidgetState extends State<MusicDashboardWidget> {
  bool _isPlaying = false;
  double _progress = 0.0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          setState(() {
            _progress += 0.005; // 0.5% every 100ms
            if (_progress >= 1.0) {
              _progress = 0.0;
              _isPlaying = false;
              timer.cancel();
            }
          });
        });
      } else {
        _timer?.cancel();
      }
    });
  }
  // Dummy data for when repository is empty or just to populate UI
  final List<Map<String, dynamic>> _dummyAlbums = [
    {'title': 'Midnight City', 'artist': 'M83', 'color': EverforestColors.blue},
    {'title': 'Currents', 'artist': 'Tame Impala', 'color': EverforestColors.purple},
    {'title': 'Blonde', 'artist': 'Frank Ocean', 'color': EverforestColors.orange},
    {'title': 'Starboy', 'artist': 'The Weeknd', 'color': EverforestColors.red},
    {'title': 'Random Access Memories', 'artist': 'Daft Punk', 'color': EverforestColors.yellow},
    {'title': 'After Hours', 'artist': 'The Weeknd', 'color': EverforestColors.aqua},
    {'title': 'Discovery', 'artist': 'Daft Punk', 'color': EverforestColors.green},
    {'title': 'IGOR', 'artist': 'Tyler, The Creator', 'color': EverforestColors.cyan},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      body: Stack(
        children: [
          // Main Scrollable Content
          CustomScrollView(
            slivers: [
              // Modern App Bar
              SliverAppBar(
                backgroundColor: EverforestColors.bg0.withValues(alpha: 0.8),
                title: const Text(
                  'Listen Now',
                  style: TextStyle(
                    color: EverforestColors.fg,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                pinned: true,
                elevation: 0,
                // Add blur effect behind app bar
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
              
              SliverToBoxAdapter(
                child: ValueListenableBuilder<List<GeneralEngineEntity>>(
                  valueListenable: EngineRepository.instance.allEntities,
                  builder: (context, entities, child) {
                    final engineTracks = EngineRepository.instance.musicTracks;
                    final displayData = engineTracks.isNotEmpty 
                        ? engineTracks.map((e) => {
                            'title': e.payload['title'] ?? 'Unknown',
                            'artist': e.payload['artist'] ?? 'Unknown',
                            'color': EverforestColors.green,
                          }).toList()
                        : _dummyAlbums;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Recently Played'),
                        _buildHorizontalList(displayData),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Library'),
                        _buildGridList(displayData),
                        // Bottom padding for the player
                        const SizedBox(height: 120),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          // Glassmorphic Bottom Player
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _buildBottomPlayer(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          color: EverforestColors.fg,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildHorizontalList(List<Map<String, dynamic>> items) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _buildAlbumCard(item, size: 150),
          );
        },
      ),
    );
  }

  Widget _buildGridList(List<Map<String, dynamic>> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 24,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _buildAlbumCard(items[index], size: double.infinity);
        },
      ),
    );
  }

  Widget _buildAlbumCard(Map<String, dynamic> item, {required double size}) {
    final color = item['color'] as Color? ?? EverforestColors.green;
    return SizedBox(
      width: size == double.infinity ? null : size,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.8),
                    color.withValues(alpha: 0.4),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.music_note_rounded,
                  size: 48,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item['title'] as String,
            style: const TextStyle(
              color: EverforestColors.fg,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            item['artist'] as String,
            style: const TextStyle(
              color: EverforestColors.grey,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPlayer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 86,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: EverforestColors.bg1.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  // Mini Album Art
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: EverforestColors.blue,
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [EverforestColors.blue, EverforestColors.purple],
                      ),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white70),
                  ),
                  const SizedBox(width: 16),
                  
                  // Track Info
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Midnight City',
                          style: TextStyle(
                            color: EverforestColors.fg,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'M83',
                          style: TextStyle(
                            color: EverforestColors.grey,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Controls
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    color: EverforestColors.fg,
                    iconSize: 32,
                    onPressed: _togglePlay,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded),
                    color: EverforestColors.fg,
                    iconSize: 32,
                    onPressed: () {
                      setState(() {
                        _progress = 0.0;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(EverforestColors.fg),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
