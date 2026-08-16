import 'package:flutter/material.dart';
import '../../../api_client.dart';
import '../../../core/telemetry/telemetry_reporter.dart';
import '../../../database/database.dart';
import '../../../theme/everforest_colors.dart';

/// Zen Code AI panel: describe the book (metadata + rating), summarize it,
/// and ask questions with chapter context. Talks to the daemon's
/// /api/v1/books/ai/* endpoints, which forward to a local LLM.
///
/// Points: every successful AI action earns stars — locally via awardPoints
/// (instant feedback) and daemon-side via telemetry rules (dedup + daily cap).
class ZenAIPanel extends StatefulWidget {
  final Book book;
  const ZenAIPanel({super.key, required this.book});

  @override
  State<ZenAIPanel> createState() => _ZenAIPanelState();
}

class _ZenAIPanelState extends State<ZenAIPanel> {
  final _question = TextEditingController();
  bool _busy = false;
  bool _checking = true;
  bool _aiAvailable = false;
  String _aiModel = '';
  String _describe = '';
  String _summary = '';
  String _answer = '';
  String _answerChapter = '';

  static const _points = {
    '/api/v1/books/ai/describe': 3,
    '/api/v1/books/ai/summarize': 3,
    '/api/v1/books/ai/chat': 1,
  };

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() => _checking = true);
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/books/ai/status');
      if (res is Map<String, dynamic>) {
        setState(() {
          _aiAvailable = res['available'] == true;
          _aiModel = res['model'] as String? ?? '';
        });
      }
    } catch (_) {
      setState(() => _aiAvailable = false);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _run(String endpoint, Map<String, dynamic> payload,
      void Function(String) onDone) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final res = await ApiClient.instance.postDaemon(endpoint, payload);
      if (res is Map<String, dynamic>) {
        onDone((res['description'] ?? res['summary'] ?? res['answer'] ?? '') as String);
        setState(() {
          final c = res['chapter'];
          _answerChapter = c is String ? c : '';
        });
        await _award(endpoint);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_aiAvailable ? 'AI error: $e' : 'AI offline — start the local LLM (Ollama)'),
            backgroundColor: EverforestColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Stars for a successful AI action: local ledger + daemon rule, then a
  /// toast with the new balance (null = daemon offline, local still counts).
  Future<void> _award(String endpoint) async {
    final action = switch (endpoint) {
      '/api/v1/books/ai/describe' => 'ai_described',
      '/api/v1/books/ai/summarize' => 'ai_summarized',
      _ => 'ai_chatted',
    };
    final pts = _points[endpoint] ?? 1;
    final db = AppDatabase.instance;
    await db.pointsDao.awardPoints(pts, 'AI ${action.replaceFirst('ai_', '')}: ${widget.book.title}');
    final res = await TelemetryReporter.instance.trackAndFlush(
        'books', action, {'book_id': widget.book.id});
    final balance = res is Map<String, dynamic> ? res['balance'] : null;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(balance != null ? '+$pts points — balance: $balance' : '+$pts points'),
          backgroundColor: EverforestColors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = {
      'book_id': widget.book.id,
      'title': widget.book.title,
      'author': widget.book.author,
    };
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text('Zen Code AI',
                      style: TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  _statusChip(),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy || !_aiAvailable ? null : () => _run('/api/v1/books/ai/describe', body, (s) {
                        setState(() => _describe = s);
                      }),
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: const Text('Describe & Rate'),
                      style: FilledButton.styleFrom(backgroundColor: EverforestColors.green),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy || !_aiAvailable ? null : () => _run('/api/v1/books/ai/summarize', body, (s) {
                        setState(() => _summary = s);
                      }),
                      icon: const Icon(Icons.summarize_outlined, size: 18),
                      label: const Text('Summarize'),
                      style: FilledButton.styleFrom(backgroundColor: EverforestColors.blue),
                    ),
                  ),
                ],
              ),
              if (_busy) const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              if (_describe.isNotEmpty)
                _card('Description', _describe, EverforestColors.green),
              if (_summary.isNotEmpty)
                _card('Summary', _summary, EverforestColors.blue),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _question,
                      enabled: _aiAvailable,
                      style: const TextStyle(color: EverforestColors.fg, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: _aiAvailable ? 'Ask about this book...' : 'AI offline — start the local LLM',
                        hintStyle: const TextStyle(color: EverforestColors.grey, fontSize: 13),
                        filled: true,
                        fillColor: EverforestColors.bg0,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: EverforestColors.bg2),
                        ),
                      ),
                      onSubmitted: (_) => _ask(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: EverforestColors.yellow),
                    onPressed: _busy || !_aiAvailable ? null : _ask,
                  ),
                ],
              ),
              if (_answerChapter.isNotEmpty)
                Text('From: $_answerChapter',
                    style: const TextStyle(color: EverforestColors.grey, fontSize: 11)),
              if (_answer.isNotEmpty)
                _card('Answer', _answer, EverforestColors.yellow),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip() {
    if (_checking) {
      return const SizedBox(
        width: 16, height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: EverforestColors.grey),
      );
    }
    final on = _aiAvailable;
    return InkWell(
      onTap: _checkStatus,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: (on ? EverforestColors.green : EverforestColors.red).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 8, color: on ? EverforestColors.green : EverforestColors.red),
            const SizedBox(width: 5),
            Text(
              on ? (_aiModel.isEmpty ? 'AI online' : _aiModel) : 'AI offline',
              style: TextStyle(color: on ? EverforestColors.green : EverforestColors.red, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  void _ask() {
    final q = _question.text.trim();
    if (q.isEmpty) return;
    _run('/api/v1/books/ai/chat', {'book_id': widget.book.id, 'question': q}, (s) {
      setState(() => _answer = s);
    });
    _question.clear();
  }

  Widget _card(String title, String text, Color accent) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(color: EverforestColors.fg, fontSize: 13)),
        ],
      ),
    );
  }
}