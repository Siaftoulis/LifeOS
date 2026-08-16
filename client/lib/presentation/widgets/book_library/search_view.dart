import 'dart:async';
import 'package:flutter/material.dart';
import '../../../api_client.dart';
import '../../../core/telemetry/telemetry_reporter.dart';
import '../../../database/database.dart';
import '../../../theme/everforest_colors.dart';

/// Search results across all configured sources (Gutenberg, Open Library,
/// MangaDex, Anna's Archive), each with a Download button, plus a live
/// panel of active download jobs polled from the daemon.
class BookSearchView extends StatefulWidget {
  const BookSearchView({super.key});

  @override
  State<BookSearchView> createState() => _BookSearchViewState();
}

class _SearchResult {
  final String source, title, author, format, size, cover, downloadUrl;
  _SearchResult.fromJson(Map<String, dynamic> j)
      : source = j['source'] ?? '',
        title = j['title'] ?? '',
        author = j['author'] ?? '',
        format = j['format'] ?? '',
        size = j['size'] ?? '',
        cover = j['cover'] ?? '',
        downloadUrl = j['download_url'] ?? '';
}

class _DownloadJob {
  final String id, title, status, error;
  final int progressBytes, totalBytes;
  _DownloadJob.fromJson(Map<String, dynamic> j)
      : id = j['id'] ?? '',
        title = j['title'] ?? '',
        status = j['status'] ?? '',
        error = j['error'] ?? '',
        progressBytes = (j['progress_bytes'] as num?)?.toInt() ?? 0,
        totalBytes = (j['total_bytes'] as num?)?.toInt() ?? 0;
}

class _BookSearchViewState extends State<BookSearchView> {
  final _controller = TextEditingController();
  List<_SearchResult> _results = [];
  List<_DownloadJob> _jobs = [];
  bool _searching = false;
  bool _downloading = false;
  Timer? _pollTimer;
  final Set<String> _awardedJobs = {}; // jobs already rewarded on DONE

  static const _sourceColors = {
    'gutenberg': EverforestColors.green,
    'openlibrary': EverforestColors.blue,
    'mangadex': EverforestColors.purple,
    'annas': EverforestColors.red,
  };

  @override
  void initState() {
    super.initState();
    _pollJobs();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollJobs());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() => _searching = true);
    try {
      final res = await ApiClient.instance
          .postDaemon('/api/v1/books/search', {'query': q});
      final list = (res as List).cast<Map<String, dynamic>>();
      setState(() => _results = list.map(_SearchResult.fromJson).toList());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Search failed — daemon unreachable?')),
        );
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _download(_SearchResult r) async {
    setState(() => _downloading = true);
    try {
      await ApiClient.instance.postDaemon('/api/v1/books/download', {
        'url': r.downloadUrl,
        'title': r.title,
        'author': r.author,
        'format': r.format,
      });
    } catch (_) {} finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _pollJobs() async {
    try {
      final res =
          await ApiClient.instance.getDaemon('/api/v1/books/downloads');
      final list = (res as List).cast<Map<String, dynamic>>();
      if (mounted) {
        for (final j in list) {
          final job = _DownloadJob.fromJson(j);
          if (job.status == 'DONE' && _awardedJobs.add(job.id)) {
            _awardDownload(job);
          }
        }
        setState(() => _jobs = list.map(_DownloadJob.fromJson).toList());
      }
    } catch (_) {}
  }

  /// A download finished: +5 stars locally and daemon-side (telemetry rule
  /// books:downloaded), once per job.
  Future<void> _awardDownload(_DownloadJob j) async {
    final db = AppDatabase.instance;
    await db.pointsDao.awardPoints(5, 'Downloaded: ${j.title}');
    final res = await TelemetryReporter.instance.trackAndFlush(
        'books', 'downloaded', {'book_id': 'bk-${j.id.replaceFirst('dl-', '')}'});
    final balance = res is Map<String, dynamic> ? res['balance'] : null;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(balance != null
              ? '+5 points — ${j.title} downloaded. Balance: $balance'
              : '+5 points — ${j.title} downloaded'),
          backgroundColor: EverforestColors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg1,
        elevation: 0,
        iconTheme: const IconThemeData(color: EverforestColors.fg),
        title: const Text('Search Books', style: TextStyle(color: EverforestColors.fg)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: EverforestColors.fg),
                    decoration: InputDecoration(
                      hintText: 'Title or author...',
                      hintStyle: const TextStyle(color: EverforestColors.grey),
                      filled: true,
                      fillColor: EverforestColors.bg1,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: EverforestColors.bg2),
                      ),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.search, color: EverforestColors.fg),
                              onPressed: _search,
                            ),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
              ],
            ),
          ),
          if (_jobs.isNotEmpty) _buildJobsPanel(),
          Expanded(
            child: _results.isEmpty
                ? const Center(
                    child: Text('Search across Gutenberg, Open Library,\nMangaDex and Anna\'s Archive',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: EverforestColors.grey)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: _results.length,
                    itemBuilder: (context, i) => _buildResultCard(_results[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsPanel() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: EverforestColors.bg2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Downloads', style: TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          ..._jobs.map((j) => _buildJobRow(j)),
        ],
      ),
    );
  }

  Widget _buildJobRow(_DownloadJob j) {
    final done = j.status == 'DONE' || j.status == 'FAILED';
    final pct = j.totalBytes > 0 ? j.progressBytes / j.totalBytes : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(j.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: EverforestColors.fg, fontSize: 12)),
              ),
              Text(
                j.status == 'FAILED' ? 'failed' : '${(pct * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: j.status == 'FAILED' ? EverforestColors.red : EverforestColors.green,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          LinearProgressIndicator(
            value: done ? (j.status == 'DONE' ? 1.0 : 0.0) : pct,
            backgroundColor: EverforestColors.bg2,
            color: j.status == 'FAILED' ? EverforestColors.red : EverforestColors.green,
            minHeight: 3,
          ),
          if (j.status == 'FAILED') Text(j.error, style: const TextStyle(color: EverforestColors.red, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildResultCard(_SearchResult r) {
    final color = _sourceColors[r.source] ?? EverforestColors.grey;
    final canDownload = r.downloadUrl.isNotEmpty;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: EverforestColors.bg2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 48,
              height: 64,
              color: EverforestColors.bg2,
              child: r.cover.isNotEmpty
                  ? Image.network(r.cover, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox())
                  : const Icon(Icons.book, color: EverforestColors.grey),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold, fontSize: 13)),
                if (r.author.isNotEmpty)
                  Text(r.author, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: EverforestColors.grey, fontSize: 11)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(r.source, style: TextStyle(color: color, fontSize: 10)),
                    ),
                    const SizedBox(width: 6),
                    Text(r.format,
                        style: const TextStyle(color: EverforestColors.grey, fontSize: 10)),
                    if (r.size.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(r.size, style: const TextStyle(color: EverforestColors.grey, fontSize: 10)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          canDownload
              ? IconButton(
                  icon: const Icon(Icons.download, color: EverforestColors.green),
                  tooltip: 'Download',
                  onPressed: _downloading ? null : () => _download(r),
                )
              : const Tooltip(
                  message: 'Browse-only (no direct file)',
                  child: Icon(Icons.remove_circle_outline, color: EverforestColors.grey, size: 20),
                ),
        ],
      ),
    );
  }
}