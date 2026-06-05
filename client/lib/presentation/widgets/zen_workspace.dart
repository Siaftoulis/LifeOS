import 'dart:async';
import 'package:flutter/material.dart';
import '../../api_client.dart';

class ZenWorkspace extends StatefulWidget {
  const ZenWorkspace({super.key});
  @override State<ZenWorkspace> createState() => _ZenWorkspaceState();
}

class _ZenWorkspaceState extends State<ZenWorkspace> {
  final TextEditingController _noteCtr = TextEditingController();
  Timer? _debounce;

  @override void initState() { super.initState(); _loadInitialNote(); }
  @override void dispose() { _debounce?.cancel(); _noteCtr.dispose(); super.dispose(); }

  Future<void> _loadInitialNote() async {
    final res = await ApiClient.instance.post('/api/obsidian/load', {});
    if (res['content'] != null && mounted) setState(() => _noteCtr.text = res['content']);
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: TextField(
          controller: _noteCtr,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: const TextStyle(color: Colors.white, fontFamily: 'JetBrainsMono', fontSize: 14),
          decoration: const InputDecoration(hintText: 'Start typing in your vault...', hintStyle: TextStyle(color: Colors.white30), border: InputBorder.none),
          onChanged: (text) {
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _debounce = Timer(const Duration(milliseconds: 800), () async {
              ApiClient.instance.post('/api/obsidian/save', {'content': text});
            });
          },
        ),
      ),
    );
  }
}
