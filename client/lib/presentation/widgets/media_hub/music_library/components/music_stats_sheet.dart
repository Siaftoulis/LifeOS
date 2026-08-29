import 'package:flutter/material.dart';
import '../../../../../core/domain_repositories.dart';
import '../../../../../theme/everforest_colors.dart';

class MusicStatsSheet extends StatefulWidget {
  const MusicStatsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MusicStatsSheet(),
    );
  }

  @override
  State<MusicStatsSheet> createState() => _MusicStatsSheetState();
}

class _MusicStatsSheetState extends State<MusicStatsSheet> {
  int _selectedDays = 30;
  MusicStats _stats = MusicStats.empty();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    final res =
        await MusicRepository.instance.getMusicStats(days: _selectedDays);
    if (mounted) {
      setState(() {
        _stats = res;
        _isLoading = false;
      });
    }
  }

  String _formatListeningTime(int totalMs) {
    final minutes = totalMs ~/ 60000;
    if (minutes < 60) return '$minutes mins';
    final hours = (minutes / 60).toStringAsFixed(1);
    return '$hours hrs';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 35,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header with Time Range Switcher
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: EverforestColors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: EverforestColors.purple.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.insights_rounded,
                    color: EverforestColors.purple, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LISTENING ANALYTICS',
                      style: TextStyle(
                        color: EverforestColors.purple,
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Your Music Habits',
                      style: TextStyle(
                        color: EverforestColors.fg,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SegmentedButton<int>(
                style: SegmentedButton.styleFrom(
                  backgroundColor: EverforestColors.bg1,
                  selectedBackgroundColor: EverforestColors.purple,
                  selectedForegroundColor: Colors.white,
                  foregroundColor: EverforestColors.grey,
                ),
                segments: const [
                  ButtonSegment(value: 7, label: Text('7D')),
                  ButtonSegment(value: 30, label: Text('30D')),
                  ButtonSegment(value: 365, label: Text('1Y')),
                ],
                selected: {_selectedDays},
                onSelectionChanged: (val) {
                  setState(() => _selectedDays = val.first);
                  _fetchStats();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: EverforestColors.purple),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // KPI Cards Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.8,
                          children: [
                            _buildKpiCard(
                              'Total Plays',
                              '${_stats.totalPlays}',
                              Icons.play_arrow_rounded,
                              EverforestColors.green,
                            ),
                            _buildKpiCard(
                              'Time Listened',
                              _formatListeningTime(_stats.totalMs),
                              Icons.timer_rounded,
                              EverforestColors.blue,
                            ),
                            _buildKpiCard(
                              'Unique Artists',
                              '${_stats.uniqueArtists}',
                              Icons.person_rounded,
                              EverforestColors.yellow,
                            ),
                            _buildKpiCard(
                              'Tracks Explored',
                              '${_stats.uniqueTracks}',
                              Icons.audiotrack_rounded,
                              EverforestColors.aqua,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Top Artists Section
                        if (_stats.topArtists.isNotEmpty) ...[
                          const Text(
                            'Top Artists',
                            style: TextStyle(
                              color: EverforestColors.fg,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _stats.topArtists.map((artist) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: EverforestColors.bg1,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: EverforestColors.purple
                                          .withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.mic_rounded,
                                        color: EverforestColors.purple,
                                        size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      artist,
                                      style: const TextStyle(
                                        color: EverforestColors.fg,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Top Genres Section
                        if (_stats.topGenres.isNotEmpty) ...[
                          const Text(
                            'Top Genres & Styles',
                            style: TextStyle(
                              color: EverforestColors.fg,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _stats.topGenres.map((genre) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: EverforestColors.bg1,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: EverforestColors.aqua
                                          .withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.category_rounded,
                                        color: EverforestColors.aqua,
                                        size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      genre,
                                      style: const TextStyle(
                                        color: EverforestColors.fg,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: EverforestColors.fg,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: EverforestColors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
