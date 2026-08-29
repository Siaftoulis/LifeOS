import 'package:flutter/material.dart';
import '../../../../../api_client.dart';
import '../../../../../theme/everforest_colors.dart';
import '../banking_models_and_helpers.dart';

class StarsChip extends StatefulWidget {
  const StarsChip({super.key});

  @override
  State<StarsChip> createState() => _StarsChipState();
}

class _StarsChipState extends State<StarsChip> {
  int _points = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _fetch();
    pointsTick.addListener(_fetch);
  }

  @override
  void dispose() {
    pointsTick.removeListener(_fetch);
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      final res = await ApiClient.instance.getDaemon('/api/v1/points/balance');
      if (mounted) {
        setState(() {
          _points = (res['points'] as num? ?? 0).toInt();
          _loaded = true;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: EverforestColors.yellow.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars, size: 14, color: EverforestColors.yellow),
          const SizedBox(width: 4),
          Text(
            '$_points',
            style: const TextStyle(
              color: EverforestColors.fg,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
