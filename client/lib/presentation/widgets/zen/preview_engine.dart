import 'package:flutter/material.dart';

class PreviewEngine extends StatelessWidget {
  final String text;
  final Map<String, bool> plugins;

  const PreviewEngine({super.key, required this.text, required this.plugins});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    return ListView(
      children: lines.map((line) {
        if (line.startsWith('```dataview') && plugins['Dataview Engine'] == true) {
          return const Card(color: Color(0xFF141416), child: ListTile(leading: Icon(Icons.table_chart, color: Color(0xFF00E5FF)), title: Text('DATAVIEW ENGINE: ACTIVE OUTPUT', style: TextStyle(fontSize: 11))));
        }
        if (line.startsWith('> [!info]') && plugins['Admonition Core'] == true) {
          return Container(margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Color(0x0C00E5FF), border: Border(left: BorderSide(color: Color(0xFF00E5FF), width: 4))), child: const Text('ADMONITION: System Handshake Nominal', style: TextStyle(fontSize: 12)));
        }
        if (line.startsWith('#')) {
          return Text(line, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF)));
        }
        return Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(line, style: const TextStyle(color: Colors.white70, fontSize: 14)));
      }).toList(),
    );
  }
}
