import 'package:flutter/material.dart';

class VaultTree extends StatelessWidget {
  final String selectedFile;
  final ValueChanged<String> onFileSelected;

  const VaultTree({super.key, required this.selectedFile, required this.onFileSelected});

  static const Map<String, List<String>> _fs = {
    'vault/00 - LifeOS DevDocs': ['Sprint_Specs.md', 'Architecture_Blueprints.md', 'Step_Trace_Log.md'],
    'vault/01 - LifeOS UserDocs': ['Profile_Identity.md', 'Hardware_Specs.md', 'System_Context.md'],
    'vault/10 - Journal & Tracking': ['Zen_Entry.md', 'Daily_Habits_Log.md', 'Network_Handshakes.md'],
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
