import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../api_client.dart';

class FlashcardsDashboard extends StatefulWidget {
  const FlashcardsDashboard({super.key});

  @override
  State<FlashcardsDashboard> createState() => _FlashcardsDashboardState();
}

class _FlashcardsDashboardState extends State<FlashcardsDashboard> {
  List<dynamic> _decks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDecks();
  }

  Future<void> _fetchDecks() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/flashcards/decks');
      if (mounted) {
        setState(() {
          _decks = res as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching flashcards decks: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: EverforestColors.bg0,
        child: const Center(child: CircularProgressIndicator(color: EverforestColors.green)),
      );
    }
    return Container(
      color: EverforestColors.bg0,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 32),
          _buildDailyTargets(),
          const SizedBox(height: 32),
          const Text(
            'Your Decks',
            style: TextStyle(
              color: EverforestColors.fg,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildDecksGrid()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spaced Repetition',
              style: TextStyle(
                color: EverforestColors.fg,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Master anything with flashcards',
              style: TextStyle(
                color: EverforestColors.fg.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: EverforestColors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EverforestColors.green.withValues(alpha: 0.5)),
          ),
          child: IconButton(
            icon: const Icon(Icons.add, color: EverforestColors.green),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildDailyTargets() {
    int toReview = 0;
    int newCards = 0;
    for (final d in _decks) {
      toReview += (d['due_cards'] as num?)?.toInt() ?? 0;
      newCards += (d['new_cards'] as num?)?.toInt() ?? 0;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EverforestColors.bg2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Study Plan',
                style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: EverforestColors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.local_fire_department, color: EverforestColors.orange, size: 16),
                    SizedBox(width: 6),
                    Text('14 Day Streak', style: TextStyle(color: EverforestColors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(label: 'To Review', value: toReview.toString(), color: EverforestColors.red, icon: Icons.refresh),
              const _Stat(label: 'Learning', value: '0', color: EverforestColors.yellow, icon: Icons.loop),
              _Stat(label: 'New Cards', value: newCards.toString(), color: EverforestColors.blue, icon: Icons.fiber_new),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: EverforestColors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Study Now',
                style: TextStyle(color: EverforestColors.bg0, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecksGrid() {
    if (_decks.isEmpty) {
      return const Center(child: Text("No decks found.", style: TextStyle(color: EverforestColors.grey)));
    }
    
    final colors = [EverforestColors.blue, EverforestColors.yellow, EverforestColors.purple, EverforestColors.green];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _decks.length,
      itemBuilder: (context, index) {
        final deck = _decks[index];
        final color = colors[index % colors.length];
        
        final due = (deck['due_cards'] as num?)?.toInt() ?? 0;
        final newCards = (deck['new_cards'] as num?)?.toInt() ?? 0;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: EverforestColors.bg1,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: EverforestColors.bg2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.style, color: color, size: 28),
              ),
              const Spacer(),
              Text(
                deck['name'] ?? 'Unknown Deck',
                style: const TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (due > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: EverforestColors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$due Due',
                        style: const TextStyle(color: EverforestColors.red, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  if (newCards > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: EverforestColors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$newCards New',
                        style: const TextStyle(color: EverforestColors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;

  const _Stat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 12),
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: EverforestColors.grey, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
