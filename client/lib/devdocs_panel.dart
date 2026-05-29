import 'dart:io';
import 'package:flutter/material.dart';

class DevDocsPanel extends StatelessWidget {
  final String activeDocPath;
  const DevDocsPanel({super.key, required this.activeDocPath});

  Future<List<String>> _load() async {
    final file = File(activeDocPath);
    if (!await file.exists()) return [];
    return await file.readAsLines(); // Async read preventing UI thread lock
  }

  List<InlineSpan> _parseLine(String line) {
    final spans = <InlineSpan>[];
    line.splitMapJoin(RegExp(r'\[\[(.*?)\]\]'),
      onMatch: (m) {
        spans.add(TextSpan(text: m[1], style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)));
        return '';
      },
      onNonMatch: (n) {
        spans.add(TextSpan(text: n, style: const TextStyle(color: Colors.white70)));
        return '';
      });
    return spans;
  }

  @override Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(16)),
      child: FutureBuilder<List<String>>(
        future: _load(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final lines = snap.data ?? [];
          if (lines.isEmpty) return const Center(child: Text("No Docs Found", style: TextStyle(color: Colors.grey)));
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lines.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SelectableText.rich(TextSpan(children: _parseLine(lines[i]))),
            ),
          );
        },
      ),
    );
  }
}
