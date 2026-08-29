import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../api_client.dart';
import 'zen_embed_models.dart';

class NotesEmbedPreview extends StatelessWidget {
  const NotesEmbedPreview({super.key, this.ref});

  /// Single-note embed reference (vault-relative path without .md).
  final String? ref;

  @override
  Widget build(BuildContext context) {
    if (ref != null && ref!.isNotEmpty) {
      return _SingleNoteEmbed(ref: ref!);
    }
    return const CardStrip(items: []);
  }
}

/// Renders one vault note from the daemon (`GET /api/v1/notes/{id}`) as a metadata card with a snippet.
class _SingleNoteEmbed extends StatefulWidget {
  const _SingleNoteEmbed({required this.ref});

  final String ref;

  @override
  State<_SingleNoteEmbed> createState() => _SingleNoteEmbedState();
}

class _SingleNoteEmbedState extends State<_SingleNoteEmbed> {
  Map<String, dynamic>? _note;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res =
          await ApiClient.instance.getDaemon('/api/v1/notes/${widget.ref}');
      if (mounted) {
        setState(() => _note = res is Map ? Map<String, dynamic>.from(res) : null);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Center(
        child: Text(
          'Note not found — tap to open the editor',
          style: TextStyle(color: EverforestColors.grey),
        ),
      );
    }
    final n = _note;
    if (n == null) {
      return const Center(
        child: CircularProgressIndicator(color: EverforestColors.green),
      );
    }

    final path = n['path'] as String? ?? '';
    final title = n['title'] as String? ?? (path.split('/').last);
    final snippet = n['snippet'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EverforestColors.bg2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: EverforestColors.bg1,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: EverforestColors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: EverforestColors.fg,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (path.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    path,
                    style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (snippet.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    snippet,
                    style: const TextStyle(
                      color: EverforestColors.grey,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
