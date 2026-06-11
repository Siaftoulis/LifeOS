import 'package:flutter/material.dart';

class VaultTree extends StatelessWidget {
  final String selectedFile;
  final ValueChanged<String> onFileSelected;

  const VaultTree({super.key, required this.selectedFile, required this.onFileSelected});

  static const Map<String, List<String>> _fs = {
    'vault/00 - System': ['Home.md'],
    'vault/01 - Tiles': [
      'Accounting.md',
      'Banking System.md',
      'Book Library.md',
      'Calendar Habit Task Manager.md',
      'Cloud & Fake Virtual Machine.md',
      'Dark Web Management.md',
      'Flashcards.md',
      'Home Management.md',
      'Home Screen.md',
      'Knowledge Base.md',
      'Maps & Live Tracking.md',
      'Movie Library.md',
      'Music Library.md',
      'Obsidian Zen Editor.md',
      'Photo Video Gallery.md',
      'Point Star System.md',
      'Preferences Setting Tab.md',
      'Project Infinity.md',
      'Virtual Machine Management.md',
      'YouTube Client.md'
    ],
    'vault/02 - Technical Specs': [
      'Accounting/What to Do.md', 
      'Banking System/What to Do.md', 
      'Book Library/What to Do.md', 
      'Calendar Habit Task Manager/What to Do.md',
      'Cloud & Fake Virtual Machine/What to Do.md',
      'Dark Web Management/What to Do.md',
      'Flashcards/What to Do.md',
      'Home Management/What to Do.md',
      'Home Screen/What to Do.md',
      'Knowledge Base/What to Do.md',
      'Maps & Live Tracking/What to Do.md',
      'Movie Library/What to Do.md',
      'Music Library/What to Do.md',
      'Obsidian Zen Editor/What to Do.md',
      'Photo Video Gallery/What to Do.md',
      'Point Star System/What to Do.md',
      'Preferences Setting Tab/What to Do.md',
      'Project Infinity/What to Do.md',
      'Virtual Machine Management/What to Do.md',
      'YouTube Client/What to Do.md'
    ],
    'vault/03 - work': ['Step_Trace_Log.md', 'subagent_delegation.md', 'system_architecture.md'],
    'vault/04 - LifeOS DevDocs': ['DATA_SCHEMAS.md', 'EMBEDDED_NETWORK.md', 'SYNC_PROTOCOL.md'],
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(color: Color(0xFF000000), border: Border(right: BorderSide(color: Color(0xFF27272A)))),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: _fs.entries.map((cat) => ExpansionTile(
          title: Text(cat.key.replaceFirst('vault/', ''), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          children: cat.value.map((file) {
            final path = '${cat.key}/$file';
            return ListTile(
              dense: true,
              title: Text(file, style: TextStyle(fontSize: 12, color: selectedFile == path ? const Color(0xFF00E5FF) : Colors.white70)),
              selected: selectedFile == path,
              onTap: () => onFileSelected(path),
            );
          }).toList(),
        )).toList(),
      ),
    );
  }
}
