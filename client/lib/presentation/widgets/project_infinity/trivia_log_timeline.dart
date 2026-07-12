import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../api_client.dart';

class TriviaLogTimeline extends StatefulWidget {
  const TriviaLogTimeline({super.key});

  @override
  State<TriviaLogTimeline> createState() => _TriviaLogTimelineState();
}

class _TriviaLogTimelineState extends State<TriviaLogTimeline> {
  List<String> _trivias = [];

  @override
  void initState() {
    super.initState();
    _fetchTrivia();
  }

  Future<void> _fetchTrivia() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/infinity/daily');
      if (res is Map<String, dynamic> && res['trivia'] != null) {
        if (mounted) {
          setState(() {
            _trivias = List<String>.from(res['trivia']);
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch trivia: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: EverforestColors.bg1, borderRadius: BorderRadius.circular(16), border: Border.all(color: EverforestColors.bg2)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Daily Trivia Logs', style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: _trivias.isEmpty
                ? const Center(child: CircularProgressIndicator(color: EverforestColors.orange))
                : ListView.builder(
                    itemCount: _trivias.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          border: Border(left: BorderSide(color: EverforestColors.orange, width: 4)),
                          color: EverforestColors.bg0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fact ${index + 1}', style: const TextStyle(color: EverforestColors.grey, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(_trivias[index], style: const TextStyle(color: EverforestColors.fg)),
                          ],
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
