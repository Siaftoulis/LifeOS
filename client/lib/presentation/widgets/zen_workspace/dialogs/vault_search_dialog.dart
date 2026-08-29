import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../api_client.dart';
import '../../../../theme/everforest_colors.dart';

/// Full-text vault search backed by `GET /api/v1/notes?q=`.
class VaultSearchDialog extends StatefulWidget {
  const VaultSearchDialog({
    super.key,
    required this.vaultPath,
    required this.onOpen,
  });

  final String vaultPath;
  final ValueChanged<String> onOpen;

  @override
  State<VaultSearchDialog> createState() => _VaultSearchDialogState();
}

class _VaultSearchDialogState extends State<VaultSearchDialog> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<dynamic> _results = [];
  bool _loading = false;
  int _querySeq = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _search);
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }
    final seq = ++_querySeq;
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance
          .getDaemon('/api/v1/notes?q=${Uri.encodeQueryComponent(query)}');
      if (!mounted || seq != _querySeq) return;
      setState(() {
        _results = res is List ? res : [];
        _loading = false;
      });
    } catch (_) {
      if (!mounted || seq != _querySeq) return;
      setState(() {
        _results = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: EverforestColors.bg1,
      title: const Text(
        'Search vault',
        style: TextStyle(color: EverforestColors.fg, fontSize: 16),
      ),
      content: SizedBox(
        width: 560,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              style: const TextStyle(color: EverforestColors.fg, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Search notes content…',
                hintStyle: TextStyle(color: EverforestColors.grey),
                prefixIcon:
                    Icon(Icons.search, color: EverforestColors.grey, size: 18),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: EverforestColors.bg2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: EverforestColors.green))
                  : _results.isEmpty
                      ? Center(
                          child: Text(
                            _controller.text.trim().isEmpty
                                ? 'Type to search note content'
                                : 'No notes found',
                            style: const TextStyle(
                                color: EverforestColors.grey),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _results.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: EverforestColors.bg2),
                          itemBuilder: (context, i) {
                            final r = _results[i] as Map;
                            final path =
                                (r['path'] as String? ?? '')
                                    .replaceAll('.md', '');
                            return ListTile(
                              dense: true,
                              title: Text(
                                r['title'] as String? ?? path,
                                style: const TextStyle(
                                    color: EverforestColors.fg, fontSize: 13),
                              ),
                              subtitle: Text(
                                path,
                                style: const TextStyle(
                                    color: EverforestColors.grey, fontSize: 11),
                              ),
                              isThreeLine: false,
                              onTap: () {
                                final rel = r['path'] as String? ?? '';
                                widget.onOpen(
                                    '${widget.vaultPath}/${rel.replaceAll('/', '\\')}');
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close', style: TextStyle(color: EverforestColors.grey)),
        ),
      ],
    );
  }
}
