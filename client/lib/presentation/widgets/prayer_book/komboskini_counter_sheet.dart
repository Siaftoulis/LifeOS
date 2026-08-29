import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/repositories/prayer_repository.dart';
import '../../../theme/everforest_colors.dart';

class KomboskiniCounterSheet extends StatefulWidget {
  const KomboskiniCounterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const KomboskiniCounterSheet(),
    );
  }

  @override
  State<KomboskiniCounterSheet> createState() => _KomboskiniCounterSheetState();
}

class _KomboskiniCounterSheetState extends State<KomboskiniCounterSheet>
    with SingleTickerProviderStateMixin {
  int _targetKnots = 100;
  int _currentKnots = 0;
  bool _isFinished = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  final List<int> _targetOptions = [33, 50, 100, 300];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onKnotTapped() {
    if (_isFinished) return;

    HapticFeedback.selectionClick();
    _animController.forward().then((_) => _animController.reverse());

    setState(() {
      _currentKnots++;
      if (_currentKnots >= _targetKnots) {
        _isFinished = true;
        HapticFeedback.heavyImpact();
        PrayerRepository.instance.completeRuleItem(
          'jesus_prayer',
          durationSec: _targetKnots * 3,
        );
      }
    });
  }

  void _resetCounter() {
    setState(() {
      _currentKnots = 0;
      _isFinished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentKnots / _targetKnots).clamp(0.0, 1.0);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 40,
            offset: Offset(0, -10),
          )
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ΝΟΕΡΑ ΠΡΟΣΕΥΧΗ',
                      style: TextStyle(
                        color: EverforestColors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Ψηφιακό Κομποσχοίνι',
                      style: TextStyle(
                        color: EverforestColors.fg,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: EverforestColors.grey),
                  tooltip: 'Reset counter',
                  onPressed: _resetCounter,
                ),
              ],
            ),
          ),

          // Knot Target Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _targetOptions.map((opt) {
                final isSel = _targetKnots == opt;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text('$opt Κόμποι'),
                    selected: isSel,
                    selectedColor:
                        EverforestColors.yellow.withValues(alpha: 0.2),
                    backgroundColor: EverforestColors.bg1,
                    labelStyle: TextStyle(
                      color: isSel
                          ? EverforestColors.yellow
                          : EverforestColors.grey,
                      fontWeight:
                          isSel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSel
                          ? EverforestColors.yellow
                          : Colors.white10,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _targetKnots = opt;
                          _currentKnots = 0;
                          _isFinished = false;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Jesus Prayer Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: EverforestColors.bg1,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: EverforestColors.yellow.withValues(alpha: 0.25),
                ),
              ),
              child: const Text(
                '«Κύριε Ιησού Χριστέ, Υιέ του Θεού, ελέησόν με τον αμαρτωλόν»',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 14.5,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ),

          const Spacer(),

          // Large Interactive Bead Counter
          GestureDetector(
            onTap: _onKnotTapped,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: _isFinished
                        ? [
                            EverforestColors.green.withValues(alpha: 0.3),
                            EverforestColors.bg1,
                          ]
                        : [
                            EverforestColors.yellow.withValues(alpha: 0.15),
                            EverforestColors.bg1,
                          ],
                  ),
                  border: Border.all(
                    color: _isFinished
                        ? EverforestColors.green
                        : EverforestColors.yellow.withValues(alpha: 0.5),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isFinished
                          ? EverforestColors.green.withValues(alpha: 0.25)
                          : EverforestColors.yellow.withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: 4,
                    )
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isFinished ? '✓' : '☩',
                        style: TextStyle(
                          color: _isFinished
                              ? EverforestColors.green
                              : EverforestColors.yellow,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_currentKnots',
                        style: const TextStyle(
                          color: EverforestColors.fg,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'από $_targetKnots',
                        style: const TextStyle(
                          color: EverforestColors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const Spacer(),

          // Progress Bar & Finished Banner
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 28),
            child: Column(
              children: [
                if (_isFinished) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: EverforestColors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: EverforestColors.green.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_rounded,
                            color: EverforestColors.yellow, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Ολοκληρώθηκε ο Κανόνας! (+20 ⭐ Stars)',
                          style: TextStyle(
                            color: EverforestColors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: EverforestColors.bg2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isFinished
                          ? EverforestColors.green
                          : EverforestColors.yellow,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Άγγιξε τον κύκλο σε κάθε επανάληψη της προσευχής',
                  style: TextStyle(
                    color: EverforestColors.grey,
                    fontSize: 11.5,
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
