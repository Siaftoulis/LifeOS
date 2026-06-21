import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import '../../../theme/everforest_colors.dart';
import '../../../database/database.dart';
import 'epub_viewer_pane.dart';

class EPUBReaderScreen extends StatefulWidget {
  final Book book;
  const EPUBReaderScreen({super.key, required this.book});

  @override
  State<EPUBReaderScreen> createState() => _EPUBReaderScreenState();
}

class _EPUBReaderScreenState extends State<EPUBReaderScreen> {
  late int _currentPage;
  late int _totalPages;
  int _sessionPagesRead = 0;
  String _selectedText = '';

  @override
  void initState() {
    super.initState();
    _currentPage = widget.book.currentPage > 0 ? widget.book.currentPage : 1;
    _totalPages = widget.book.totalPages > 0 ? widget.book.totalPages : 300;
  }

  Future<void> _updateProgress() async {
    final db = AppDatabase.instance;
    await db.booksDao.updateBookProgress(
      widget.book.id,
      _currentPage,
      DateTime.now().millisecondsSinceEpoch,
    );

    if (_sessionPagesRead >= 10) {
      _sessionPagesRead -= 10;
      await db.pointsDao.awardPoints(1, 'Read 10 pages of ${widget.book.title}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Earning: +1 Star Point for reading!'),
            backgroundColor: EverforestColors.green,
          ),
        );
      }
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
        _sessionPagesRead++;
      });
      _updateProgress();
    }
  }

  void _prevPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _updateProgress();
    }
  }

  Future<void> _addHighlight() async {
    if (_selectedText.isEmpty) return;
    final db = AppDatabase.instance;
    final highlightId = 'hl-${DateTime.now().millisecondsSinceEpoch}';
    await db.booksDao.insertHighlight(BookHighlightsCompanion.insert(
      id: highlightId,
      bookId: widget.book.id,
      textContent: _selectedText,
      noteContent: const Value('User highlight'),
      pageNumber: Value(_currentPage),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      isDirty: const Value(1),
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Highlight saved!'), backgroundColor: EverforestColors.purple),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EverforestColors.bg1,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg0,
        elevation: 0,
        title: Text(widget.book.title, style: const TextStyle(color: EverforestColors.fg, fontSize: 16)),
        iconTheme: const IconThemeData(color: EverforestColors.fg),
        actions: [
          if (_selectedText.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.border_color, color: EverforestColors.yellow),
              onPressed: _addHighlight,
              tooltip: 'Highlight selected text',
            ),
        ],
      ),
      body: EPUBViewerPane(
        currentPage: _currentPage,
        totalPages: _totalPages,
        selectedText: _selectedText,
        onSelectionChanged: (text) => setState(() => _selectedText = text),
        onPrevPage: _prevPage,
        onNextPage: _nextPage,
      ),
    );
  }
}
