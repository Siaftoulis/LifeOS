import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class FlashcardsDashboard extends StatelessWidget {
  const FlashcardsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
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
                color: EverforestColors.fg.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: EverforestColors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EverforestColors.green.withOpacity(0.5)),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EverforestColors.bg2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                  color: EverforestColors.orange.withOpacity(0.2),
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(label: 'To Review', value: '105', color: EverforestColors.red, icon: Icons.refresh),
              _Stat(label: 'Learning', value: '42', color: EverforestColors.yellow, icon: Icons.loop),
              _Stat(label: 'New Cards', value: '20', color: EverforestColors.blue, icon: Icons.fiber_new),
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
    final decks = [
      {'title': 'Go Programming', 'due': 45, 'new': 10, 'progress': 0.7, 'color': EverforestColors.blue},
      {'title': 'Spanish Vocabulary', 'due': 120, 'new': 0, 'progress': 0.4, 'color': EverforestColors.yellow},
      {'title': 'System Design', 'due': 15, 'new': 5, 'progress': 0.85, 'color': EverforestColors.purple},
      {'title': 'Geography', 'due': 0, 'new': 0, 'progress': 1.0, 'color': EverforestColors.green},
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: decks.length,
      itemBuilder: (context, index) {
        final deck = decks[index];
        final isComplete = deck['due'] == 0 && deck['new'] == 0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: EverforestColors.bg1,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: EverforestColors.bg2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.folder_copy_outlined, color: deck['color'] as Color, size: 28),
                  const Spacer(),
                  if (isComplete)
                    const Icon(Icons.check_circle, color: EverforestColors.green, size: 20)
                ],
              ),
              const SizedBox(height: 16),
              Text(
                deck['title'] as String,
                style: const TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              if (!isComplete)
                Row(
                  children: [
                    if ((deck['due'] as int) > 0)
                      Text('${deck['due']} Due  ', style: const TextStyle(color: EverforestColors.red, fontSize: 13, fontWeight: FontWeight.bold)),
                    if ((deck['new'] as int) > 0)
                      Text('${deck['new']} New', style: const TextStyle(color: EverforestColors.blue, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                )
              else
                const Text('All caught up!', style: TextStyle(color: EverforestColors.green, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: deck['progress'] as double,
                backgroundColor: EverforestColors.bg2,
                valueColor: AlwaysStoppedAnimation<Color>(deck['color'] as Color),
                borderRadius: BorderRadius.circular(4),
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
            color: color.withOpacity(0.1),
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
