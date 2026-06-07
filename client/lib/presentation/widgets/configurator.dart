import 'package:flutter/material.dart';
import '../../theme/everforest_colors.dart';

class GridConfigurator extends StatelessWidget {
  const GridConfigurator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('SYSTEM PREFERENCES', style: TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 1.5)),
          const SizedBox(height: 24),
          _buildToggleItem('Enable background daemon sync', true),
          _buildToggleItem('Spatial Navigation Gestures', true),
          _buildToggleItem('Developer Mode', false),
          const SizedBox(height: 48),
          const Text('SPATIAL MATRIX EDITOR', style: TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 1.5)),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EverforestColors.grey.withOpacity(0.5), width: 1.5),
              ),
              padding: const EdgeInsets.all(24),
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildMatrixSlot('Radar', true),
                  _buildMatrixSlot('Obsidian', true),
                  _buildMatrixSlot('Infra', true),
                  _buildMatrixSlot('Quests', true),
                  _buildMatrixSlot('HOME', true, isCenter: true),
                  _buildMatrixSlot('Media', true),
                  _buildMatrixSlot('Capture', true),
                  _buildMatrixSlot('Config', true),
                  _buildMatrixSlot('Void', false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: EverforestColors.fg, fontSize: 14)),
          Container(
            width: 48,
            height: 24,
            decoration: BoxDecoration(
              color: value ? EverforestColors.fg : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: EverforestColors.fg, width: 1.5),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.all(2),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? EverforestColors.bg0 : EverforestColors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixSlot(String label, bool filled, {bool isCenter = false}) {
    return Container(
      decoration: BoxDecoration(
        color: filled ? (isCenter ? EverforestColors.fg : Colors.transparent) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: filled ? (isCenter ? EverforestColors.fg : EverforestColors.grey) : EverforestColors.grey.withOpacity(0.3),
          width: 1.5,
          style: filled ? BorderStyle.solid : BorderStyle.none,
        ),
      ),
      child: Center(
        child: Text(
          filled ? label : '+',
          style: TextStyle(
            color: filled ? (isCenter ? EverforestColors.bg0 : EverforestColors.fg) : EverforestColors.grey,
            fontSize: filled ? 10 : 24,
            fontWeight: isCenter ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
