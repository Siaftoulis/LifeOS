import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../api_client.dart';
import '../../../database/database.dart';
import '../../../theme/everforest_colors.dart';

/// Minimal CBZ (zip of images) reader for manga from MangaDex.
/// ponytail: no chapter nav, no zoom — plain page flip; add when reading
/// flow demands it.
class CBZReaderScreen extends StatefulWidget {
  final Book book;
  const CBZReaderScreen({super.key, required this.book});

  @override
  State<CBZReaderScreen> createState() => _CBZReaderScreenState();
}

class _CBZReaderScreenState extends State<CBZReaderScreen> {
  List<Uint8List>? _pages;
  String? _error;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiClient.instance.daemonUrl}/api/v1/books/${widget.book.id}/file'),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final archive = ZipDecoder().decodeBytes(res.bodyBytes);
      final isImage = (ArchiveFile f) {
        final name = f.name.toLowerCase();
        return name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png') || name.endsWith('.webp');
      };
      final pages = archive.files.where(isImage).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      setState(() {
        _pages = [for (final f in pages) Uint8List.fromList(f.content as List<int>)];
      });
    } catch (e) {
      setState(() => _error = 'Could not open file: $e');
    }
  }

  Future<void> _sync() async {
    try {
      await ApiClient.instance.postDaemon('/api/v1/books/progress', {
        'book_id': widget.book.id,
        'page': _current + 1,
        'seconds': 0,
      });
    } catch (_) {}
  }

  void _go(int delta) {
    if (_pages == null) return;
    final next = (_current + delta).clamp(0, _pages!.length - 1);
    if (next != _current) {
      setState(() => _current = next);
      _sync();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg0,
        elevation: 0,
        title: Text(widget.book.title, style: const TextStyle(color: EverforestColors.fg, fontSize: 15)),
        iconTheme: const IconThemeData(color: EverforestColors.fg),
      ),
      body: _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: EverforestColors.red)))
          : _pages == null
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : GestureDetector(
                  onTapUp: (d) {
                    final w = MediaQuery.of(context).size.width;
                    if (d.globalPosition.dx < w / 3) {
                      _go(-1);
                    } else if (d.globalPosition.dx > w * 2 / 3) {
                      _go(1);
                    }
                  },
                  child: Stack(
                    children: [
                      Center(
                        child: Image.memory(
                          _pages![_current],
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: EverforestColors.bg2.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_current + 1} / ${_pages!.length}',
                              style: const TextStyle(color: EverforestColors.fg, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}