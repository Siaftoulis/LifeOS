import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'markdown_storage.dart';
import '../../api_client.dart';

class ZenEditor extends StatefulWidget {
  const ZenEditor({super.key});
  @override State<ZenEditor> createState() => _ZenState();
}

class _ZenState extends State<ZenEditor> {
  final _focus = FocusNode(); final _ctrl = TextEditingController();
  bool _hasFocus = false; Timer? _timer;

  @override void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _hasFocus = _focus.hasFocus));
    _ctrl.addListener(() {
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 500), () async {
        final val = _ctrl.text;
        MarkdownStorage.saveNote('sync_draft.md', val);
        try {
          final baseUrl = ApiClient.instance.baseUrl;
          final syncUrl = baseUrl.replaceAll(':8080', ':50051') + '/api/markdown/sync';
          await http.post(Uri.parse(syncUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'filename': 'sync_draft.md', 'content': val}));
        } catch (_) {}
      });
    });
  }

  @override void dispose() { _focus.dispose(); _ctrl.dispose(); _timer?.cancel(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return Column(children: [
      AnimatedOpacity(
        opacity: _hasFocus ? 0.0 : 1.0, duration: const Duration(milliseconds: 300),
        child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Z E N', style: TextStyle(color: Colors.white24, letterSpacing: 4, fontWeight: FontWeight.bold))),
      ),
      Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: TextField(
        focusNode: _focus, controller: _ctrl, maxLines: null, cursorColor: const Color(0xFF00E5FF),
        style: const TextStyle(color: Color(0xFFFAFAFA), fontSize: 18, height: 1.6, letterSpacing: -0.36),
        decoration: const InputDecoration(border: InputBorder.none, hintText: 'Start writing...', hintStyle: TextStyle(color: Colors.white24)),
      ))),
    ]);
  }
}
