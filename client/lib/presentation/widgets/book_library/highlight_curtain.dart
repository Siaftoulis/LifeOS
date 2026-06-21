import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../database/database.dart';
import '../../../api_client.dart';

class HighlightCurtain extends StatelessWidget {
  const HighlightCurtain({super.key});

  String _generateUuid() {
    final random = Random();
    final parts = List.generate(4, (_) => random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0'));
    return parts.join('-');
  }

  Future<void> _exportHighlight(BuildContext context, BookHighlight highlight) async {
    final db = AppDatabase.instance;
    final bookList = await db.booksDao.watchAllBooks().first;
    final book = bookList.firstWhere(
      (b) => b.id == highlight.bookId,
      orElse: () => Book(id: '', title: 'Unknown', filePath: '', updatedAt: 0, isDirty: 0, currentPage: 0, totalPages: 0),
    );

    final sanitizedTitle = book.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final relativePath = 'Highlights_$sanitizedTitle.md';
    final file = File('vault/$relativePath');

    String fileContent;
    if (file.existsSync()) {
      final currentContent = file.readAsStringSync();
      fileContent = '$currentContent\n- "${highlight.textContent}" (Page ${highlight.pageNumber ?? 0})';
    } else {
      final uuid = _generateUuid();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      fileContent = '''---
id: "$uuid"
updated_at: $timestamp
synced_at: null
---
# Highlights: ${book.title}

[[${book.title}]]

- "${highlight.textContent}" (Page ${highlight.pageNumber ?? 0})''';
    }

    try {
      file.writeAsStringSync(fileContent);
      await ApiClient.instance.postDaemon('/api/markdown/sync', {
        'file_path': relativePath,
        'content': fileContent,
      });

      await db.pointsDao.awardPoints(2, 'Exported highlight of ${book.title}');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exported to Zen Editor (+2 Stars)!'), backgroundColor: EverforestColors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: EverforestColors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = AppDatabase.instance;
    return AlertDialog(
      backgroundColor: EverforestColors.bg1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: EverforestColors.bg2),
      ),
      title: const Text('Highlights & Notes', style: TextStyle(color: EverforestColors.fg)),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: StreamBuilder<List<BookHighlight>>(
          stream: db.booksDao.watchAllHighlights(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final highlights = snapshot.data!;
            if (highlights.isEmpty) {
              return const Center(child: Text('No highlights available.', style: TextStyle(color: EverforestColors.grey)));
            }
            return ListView.separated(
              itemCount: highlights.length,
              separatorBuilder: (context, index) => const Divider(color: EverforestColors.bg2),
              itemBuilder: (context, index) {
                final hl = highlights[index];
                return ListTile(
                  title: Text(
                    '"${hl.textContent}"',
                    style: const TextStyle(color: EverforestColors.fg, fontStyle: FontStyle.italic, fontSize: 14),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Page ${hl.pageNumber ?? 0} • ${hl.noteContent ?? ""}',
                      style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.send_to_mobile, color: EverforestColors.green),
                    onPressed: () => _exportHighlight(context, hl),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Close', style: TextStyle(color: EverforestColors.grey)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
