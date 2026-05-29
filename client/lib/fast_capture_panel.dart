import 'package:flutter/material.dart';

class FastCapturePanel extends StatefulWidget {
  final dynamic db;
  const FastCapturePanel({super.key, required this.db});
  @override State<FastCapturePanel> createState() => _FCPState();
}

class _FCPState extends State<FastCapturePanel> {
  final _c = TextEditingController();

  void _save() async {
    if (_c.text.trim().isEmpty) return;
    final iso = DateTime.now().toIso8601String();
    final p = "---\ntitle: Fast Capture\ndate: $iso\ntags: [fast-capture]\n---\n\n${_c.text.trim()}";
    await widget.db.customStatement('INSERT INTO notes (id, content, updated_at, is_dirty) VALUES (?, ?, ?, 1)', ["note_${DateTime.now().millisecondsSinceEpoch}", p, DateTime.now().millisecondsSinceEpoch]);
    _c.clear(); FocusScope.of(context).unfocus();
  }

  @override Widget build(BuildContext context) {
    return Column(children: [
      Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(24)), child: Row(children: [
        Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(controller: _c, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "Capture...", hintStyle: TextStyle(color: Colors.white38), border: InputBorder.none), maxLines: null))),
        IconButton(icon: const Icon(Icons.send_rounded, color: Colors.blueAccent), onPressed: _save)
      ])),
      Expanded(child: StreamBuilder(stream: widget.db.customSelect('SELECT * FROM notes ORDER BY updated_at DESC LIMIT 5').watch(), builder: (ctx, snap) {
        final List notes = snap.data ?? [];
        return ListView.builder(itemCount: notes.length, itemBuilder: (_, i) {
          final n = notes[i].data;
          return Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(12)), child: ListTile(
            title: Text(n['id'], style: const TextStyle(color: Colors.white70, fontSize: 12)),
            subtitle: Text(n['content'].split('\n').last, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
            trailing: n['is_dirty'] == 1 ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 2)) : const Icon(Icons.check_circle, color: Colors.green),
          ));
        });
      }))
    ]);
  }
}
