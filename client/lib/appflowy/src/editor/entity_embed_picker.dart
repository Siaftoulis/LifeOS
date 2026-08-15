import 'dart:async';
import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../api_client.dart';

/// Search dialog backing the `/movie` and `/book` slash commands. Queries the
/// daemon (`GET {endpoint}?q=&status=`), returns the picked entity id.
class EntityEmbedPickerDialog extends StatefulWidget {
  const EntityEmbedPickerDialog({
    super.key,
    required this.endpoint,
    required this.title,
    required this.icon,
    required this.subtitleOf,
    this.statuses = const [],
  });

  /// API path, e.g. `/api/v1/movies`.
  final String endpoint;
  final String title;
  final IconData icon;

  /// Status filter chips shown when non-empty (e.g. movies: WATCHED).
  final List<String> statuses;

  /// Builds the one-line subtitle under each result title.
  final String Function(Map<String, dynamic> entity) subtitleOf;

  @override
  State<EntityEmbedPickerDialog> createState() => _EntityEmbedPickerDialogState();
}

class _EntityEmbedPickerDialogState extends State<EntityEmbedPickerDialog> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String? _status;
  List<Map<String, dynamic>> _entities = [];
  bool _loading = false;
  int _querySeq = 0;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _search);
  }

  Future<void> _search() async {
    final seq = ++_querySeq;
    setState(() => _loading = true);
    final query = _controller.text.trim();
    final params = [
      if (query.isNotEmpty) 'q=${Uri.encodeQueryComponent(query)}',
      if (_status != null) 'status=$_status',
    ];
    try {
      final res = await ApiClient.instance
          .getDaemon('${widget.endpoint}${params.isEmpty ? '' : '?${params.join('&')}'}');
      if (!mounted || seq != _querySeq) return;
      setState(() {
        _entities = res is List
            ? res
                .whereType<Map>()
                .map((m) => Map<String, dynamic>.from(m))
                .toList()
            : [];
        _loading = false;
      });
    } catch (_) {
      if (!mounted || seq != _querySeq) return;
      setState(() {
        _entities = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: EverforestColors.bg1,
      title: Text(
        widget.title,
        style: const TextStyle(color: EverforestColors.fg, fontSize: 16),
      ),
      content: SizedBox(
        width: 420,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onQueryChanged,
              style: const TextStyle(color: EverforestColors.fg, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search…',
                hintStyle: const TextStyle(color: EverforestColors.grey),
                prefixIcon:
                    const Icon(Icons.search, color: EverforestColors.grey, size: 18),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: EverforestColors.bg2),
                ),
              ),
            ),
            if (widget.statuses.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final s in [null, ...widget.statuses])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(
                          s == null
                              ? 'All'
                              : s[0] + s.substring(1).toLowerCase(),
                          style: const TextStyle(fontSize: 11),
                        ),
                        selected: _status == s,
                        onSelected: (_) {
                          setState(() => _status = s);
                          _search();
                        },
                        selectedColor:
                            EverforestColors.green.withValues(alpha: 0.35),
                        backgroundColor: EverforestColors.bg2,
                        labelStyle: TextStyle(
                          color: _status == s
                              ? EverforestColors.fg
                              : EverforestColors.grey,
                        ),
                        side: const BorderSide(color: EverforestColors.bg2),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: EverforestColors.green,
                      ),
                    )
                  : _entities.isEmpty
                      ? const Center(
                          child: Text(
                            'Nothing found',
                            style: TextStyle(color: EverforestColors.grey),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _entities.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: Color(0xFF2E383C)),
                          itemBuilder: (context, index) {
                            final e = _entities[index];
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                widget.icon,
                                color: EverforestColors.green,
                                size: 20,
                              ),
                              title: Text(
                                e['title']?.toString() ?? '',
                                style: const TextStyle(
                                  color: EverforestColors.fg,
                                  fontSize: 13.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                widget.subtitleOf(e),
                                style: const TextStyle(
                                  color: EverforestColors.grey,
                                  fontSize: 11.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () =>
                                  Navigator.of(context).pop(e['id'] as String?),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
