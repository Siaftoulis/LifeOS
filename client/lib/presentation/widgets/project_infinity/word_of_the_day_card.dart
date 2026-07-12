import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../api_client.dart';

class WordOfTheDayCard extends StatefulWidget {
  const WordOfTheDayCard({super.key});

  @override
  State<WordOfTheDayCard> createState() => _WordOfTheDayCardState();
}

class _WordOfTheDayCardState extends State<WordOfTheDayCard> {
  Map<String, String>? _wordData;

  @override
  void initState() {
    super.initState();
    _fetchWord();
  }

  Future<void> _fetchWord() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/infinity/daily');
      if (res is Map<String, dynamic> && res['word'] != null) {
        if (mounted) {
          setState(() {
            _wordData = Map<String, String>.from(res['word']);
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch word of the day: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_wordData == null) {
      return Container(
        decoration: BoxDecoration(color: EverforestColors.bg1, borderRadius: BorderRadius.circular(16), border: Border.all(color: EverforestColors.bg2)),
        padding: const EdgeInsets.all(32),
        child: const Center(child: CircularProgressIndicator(color: EverforestColors.yellow)),
      );
    }

    return Container(
      decoration: BoxDecoration(color: EverforestColors.bg1, borderRadius: BorderRadius.circular(16), border: Border.all(color: EverforestColors.bg2)),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Word of the Day', style: TextStyle(color: EverforestColors.grey, fontSize: 16)),
          const SizedBox(height: 16),
          Text(_wordData!['greek'] ?? 'Ενσυναίσθηση', style: const TextStyle(color: EverforestColors.yellow, fontSize: 48, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_wordData!['english'] ?? 'Empathy', style: const TextStyle(color: EverforestColors.blue, fontSize: 24, fontStyle: FontStyle.italic)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: EverforestColors.bg0, borderRadius: BorderRadius.circular(8)),
            child: Text(
              _wordData!['definition'] ?? 'The ability to understand and share the feelings of another.',
              style: const TextStyle(color: EverforestColors.fg, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          )
        ],
      ),
    );
  }
}
