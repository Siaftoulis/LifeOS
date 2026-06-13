import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class GridConfiguratorWidget extends StatelessWidget {
  const GridConfiguratorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: EverforestColors.bg1, borderRadius: BorderRadius.circular(16), border: Border.all(color: EverforestColors.bg2)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Launcher Layout Grid', style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: List.generate(9, (index) => _DragSlot(index)),
            ),
          )
        ],
      ),
    );
  }
}

class _DragSlot extends StatelessWidget {
  final int index;
  const _DragSlot(this.index);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: EverforestColors.bg2, borderRadius: BorderRadius.circular(8)),
      child: Center(child: Text('Slot ${index + 1}', style: const TextStyle(color: EverforestColors.grey))),
    );
  }
}
