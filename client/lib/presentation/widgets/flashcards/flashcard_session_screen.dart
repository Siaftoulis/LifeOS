import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class FlashcardSessionScreen extends StatefulWidget {
  const FlashcardSessionScreen({super.key});

  @override
  State<FlashcardSessionScreen> createState() => _FlashcardSessionScreenState();
}

class _FlashcardSessionScreenState extends State<FlashcardSessionScreen> {
  bool _isFlipped = false;

  void _flipCard() {
    setState(() => _isFlipped = true);
  }

  void _scoreCard(int quality) {
    setState(() => _isFlipped = false);
    // Move to next card...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg0,
        elevation: 0,
        iconTheme: const IconThemeData(color: EverforestColors.fg),
        title: const Text('Study Session', style: TextStyle(color: EverforestColors.fg)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LinearProgressIndicator(value: 0.1, backgroundColor: EverforestColors.bg2, color: EverforestColors.green),
              const SizedBox(height: 24),
              Expanded(
                child: GestureDetector(
                  onTap: _flipCard,
                  child: Container(
                    decoration: BoxDecoration(
                      color: EverforestColors.bg1,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: EverforestColors.bg2),
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'What does SRS stand for?',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: EverforestColors.fg, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          if (_isFlipped) ...[
                            const SizedBox(height: 32),
                            const Divider(color: EverforestColors.bg2),
                            const SizedBox(height: 32),
                            const Text(
                              'Spaced Repetition System',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: EverforestColors.green, fontSize: 20),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_isFlipped)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ScoreBtn(label: 'Again', color: EverforestColors.red, onTap: () => _scoreCard(0)),
                    _ScoreBtn(label: 'Hard', color: EverforestColors.orange, onTap: () => _scoreCard(2)),
                    _ScoreBtn(label: 'Good', color: EverforestColors.green, onTap: () => _scoreCard(4)),
                    _ScoreBtn(label: 'Easy', color: EverforestColors.blue, onTap: () => _scoreCard(5)),
                  ],
                )
              else
                const Center(child: Text('Tap the card to show answer', style: TextStyle(color: EverforestColors.grey))),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ScoreBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: EverforestColors.bg0),
      onPressed: onTap,
      child: Text(label),
    );
  }
}
