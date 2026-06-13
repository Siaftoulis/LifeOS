import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class RelationshipGraphWidget extends StatelessWidget {
  const RelationshipGraphWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EverforestColors.bg2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Active Dependencies', style: TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: const [
                _RelationRow(source: 'Calculus I', target: 'Linear Algebra', type: 'REQUIRES'),
                _RelationRow(source: 'Docker Internals', target: 'Linux Namespaces', type: 'EXPANDS'),
                _RelationRow(source: 'Stoicism', target: 'Epicureanism', type: 'CONTRADICTS'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RelationRow extends StatelessWidget {
  final String source, target, type;
  const _RelationRow({required this.source, required this.target, required this.type});

  @override
  Widget build(BuildContext context) {
    final typeColor = type == 'REQUIRES' ? EverforestColors.red : type == 'EXPANDS' ? EverforestColors.aqua : EverforestColors.yellow;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(source, style: const TextStyle(color: EverforestColors.fg), textAlign: TextAlign.right)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Text(type, style: TextStyle(color: typeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                Icon(Icons.arrow_right_alt, color: typeColor, size: 16),
              ],
            ),
          ),
          Expanded(child: Text(target, style: const TextStyle(color: EverforestColors.grey))),
        ],
      ),
    );
  }
}
