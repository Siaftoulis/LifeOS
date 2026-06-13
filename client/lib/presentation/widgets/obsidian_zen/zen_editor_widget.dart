import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'markdown_focus_viewport.dart';
import 'notes_graph_canvas.dart';

class ZenEditorWidget extends StatelessWidget {
  const ZenEditorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Obsidian Zen', style: TextStyle(color: EverforestColors.fg, fontSize: 24, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                icon: const Icon(Icons.hub),
                label: const Text('View Graph'),
                style: ElevatedButton.styleFrom(backgroundColor: EverforestColors.bg2),
                onPressed: () => _showGraph(context),
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 1, child: _buildFileList()),
                const SizedBox(width: 16),
                const Expanded(flex: 3, child: MarkdownFocusViewport()),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFileList() {
    return Container(
      decoration: BoxDecoration(color: EverforestColors.bg1, borderRadius: BorderRadius.circular(12), border: Border.all(color: EverforestColors.bg2)),
      child: ListView(
        children: const [
          ListTile(leading: Icon(Icons.description, color: EverforestColors.grey), title: Text('Ideas.md', style: TextStyle(color: EverforestColors.fg))),
          ListTile(leading: Icon(Icons.description, color: EverforestColors.grey), title: Text('Journal.md', style: TextStyle(color: EverforestColors.fg))),
          ListTile(leading: Icon(Icons.description, color: EverforestColors.grey), title: Text('Tasks.md', style: TextStyle(color: EverforestColors.fg))),
        ],
      ),
    );
  }

  void _showGraph(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const Dialog(
        backgroundColor: Colors.transparent,
        child: NotesGraphCanvas(),
      ),
    );
  }
}
