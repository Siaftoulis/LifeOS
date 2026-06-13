import 'package:flutter/material.dart';
import 'editor_theme.dart';
import 'markdown_viewport.dart';
import 'notes_graph.dart';
import '../../database/database.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ZenEditorWidget extends StatefulWidget {
  const ZenEditorWidget({Key? key}) : super(key: key);

  @override
  State<ZenEditorWidget> createState() => _ZenEditorWidgetState();
}

class _ZenEditorWidgetState extends State<ZenEditorWidget> {
  String _currentContent = "# New Note\n\nWelcome to Zen Mode.";
  final String _currentFileId = "active_note";

  Future<void> _syncToBackend(String content) async {
    // 1. Mark dirty in DB
    // AppDatabase.instance.markdownDao.markDirty(_currentFileId);

    // 2. Sync to daemon via REST API
    try {
      await http.post(
        Uri.parse('http://localhost:8080/api/markdown/sync'),
        body: jsonEncode({
          "file_path": "active_note.md",
          "content": content,
        }),
      );
    } catch (e) {
      debugPrint("Sync error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ZenEditorTheme.theme,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: EverforestColors.bg1,
          title: const Text('Obsidian Zen Editor', style: TextStyle(color: EverforestColors.fg)),
          actions: [
            IconButton(
              icon: const Icon(Icons.sync, color: EverforestColors.accent),
              onPressed: () => _syncToBackend(_currentContent),
            )
          ],
        ),
        body: Row(
          children: [
            // Left: Notes Graph Canvas
            const Expanded(
              flex: 1,
              child: NotesGraphCanvas(),
            ),
            // Right: Focus Editor
            Expanded(
              flex: 2,
              child: MarkdownFocusViewport(
                initialText: _currentContent,
                onTextChanged: (text) {
                  _currentContent = text;
                  // Auto-sync could be triggered here with a debounce
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
