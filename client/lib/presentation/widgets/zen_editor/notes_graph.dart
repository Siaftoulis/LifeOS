import 'package:flutter/material.dart';
import 'editor_theme.dart';

class NotesGraphCanvas extends StatelessWidget {
  const NotesGraphCanvas({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg0,
        border: Border.all(color: EverforestColors.bg2, width: 1),
      ),
      child: Stack(
        children: [
          // Center mock node
          Align(
            alignment: Alignment.center,
            child: _buildMockNode('Home Node', EverforestColors.accent),
          ),
          // Other mock nodes
          Positioned(
            top: 50,
            left: 50,
            child: _buildMockNode('Note 1', EverforestColors.fg),
          ),
          Positioned(
            bottom: 50,
            right: 50,
            child: _buildMockNode('Note 2', EverforestColors.fg),
          ),
        ],
      ),
    );
  }

  Widget _buildMockNode(String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        label,
        style: const TextStyle(color: EverforestColors.fg, fontSize: 12),
      ),
    );
  }
}
