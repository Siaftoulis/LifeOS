import 'package:flutter/material.dart';

class BudgetSplitIndicator extends StatelessWidget {
  final double essentialsRatio;
  final double savingsRatio;
  final double personalRatio;

  const BudgetSplitIndicator({
    Key? key,
    this.essentialsRatio = 0.5,
    this.savingsRatio = 0.2,
    this.personalRatio = 0.3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('MONTHLY SPLIT (50/20/30)', style: TextStyle(color: Color(0xFF859289), fontSize: 12, letterSpacing: 1.2)),
            Icon(Icons.pie_chart_outline, color: Color(0xFF859289), size: 16),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                Expanded(
                  flex: (essentialsRatio * 100).toInt(),
                  child: Container(color: const Color(0xFFa7c080)), // Green
                ),
                Expanded(
                  flex: (savingsRatio * 100).toInt(),
                  child: Container(color: const Color(0xFF7fbbb3)), // Blue
                ),
                Expanded(
                  flex: (personalRatio * 100).toInt(),
                  child: Container(color: const Color(0xFFdbbc7f)), // Yellow
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLegendItem('Essentials', const Color(0xFFa7c080), '${(essentialsRatio * 100).toInt()}%'),
            _buildLegendItem('Savings', const Color(0xFF7fbbb3), '${(savingsRatio * 100).toInt()}%'),
            _buildLegendItem('Personal', const Color(0xFFdbbc7f), '${(personalRatio * 100).toInt()}%'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, String percentage) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(
          '$label $percentage',
          style: const TextStyle(color: Color(0xFFd3c6aa), fontSize: 11),
        ),
      ],
    );
  }
}
