import 'package:flutter/material.dart';
import '../../../../../core/domain_repositories.dart';
import '../../../../../theme/everforest_colors.dart';

class CreatePlaylistDialog extends StatefulWidget {
  const CreatePlaylistDialog({
    super.key,
    this.initialPlaylist,
  });

  final Playlist? initialPlaylist;

  static Future<Playlist?> show(BuildContext context,
      {Playlist? initialPlaylist}) {
    return showDialog<Playlist>(
      context: context,
      builder: (_) => CreatePlaylistDialog(initialPlaylist: initialPlaylist),
    );
  }

  @override
  State<CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends State<CreatePlaylistDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  bool _isSmart = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl =
        TextEditingController(text: widget.initialPlaylist?.name ?? '');
    _descCtrl =
        TextEditingController(text: widget.initialPlaylist?.description ?? '');
    _isSmart = widget.initialPlaylist?.isSmart ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      if (widget.initialPlaylist != null) {
        final ok = await MusicRepository.instance.updatePlaylist(
          widget.initialPlaylist!.id,
          PlaylistUpdate(
            name: title,
            description: _descCtrl.text.trim(),
          ),
        );
        if (mounted && ok) {
          final updated =
              await MusicRepository.instance.getPlaylist(widget.initialPlaylist!.id);
          Navigator.pop(context, updated);
        }
      } else {
        final created = await MusicRepository.instance.createPlaylist(
          PlaylistCreate(
            name: title,
            description: _descCtrl.text.trim(),
            isSmart: _isSmart,
          ),
        );
        if (mounted && created != null) {
          await MusicRepository.instance.loadPlaylists();
          Navigator.pop(context, created);
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialPlaylist != null;
    return AlertDialog(
      backgroundColor: EverforestColors.bg1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: EverforestColors.bg2),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: EverforestColors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isEditing ? Icons.edit_rounded : Icons.playlist_add_rounded,
              color: EverforestColors.green,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isEditing ? 'Edit Playlist' : 'New Playlist',
            style: const TextStyle(
              color: EverforestColors.fg,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              style: const TextStyle(color: EverforestColors.fg),
              decoration: InputDecoration(
                labelText: 'Playlist Name',
                labelStyle: const TextStyle(color: EverforestColors.grey),
                hintText: 'e.g. Midnight Grooves, Study Session',
                hintStyle:
                    const TextStyle(color: EverforestColors.grey, fontSize: 13),
                filled: true,
                fillColor: EverforestColors.bg0,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              style: const TextStyle(color: EverforestColors.fg),
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                labelStyle: const TextStyle(color: EverforestColors.grey),
                filled: true,
                fillColor: EverforestColors.bg0,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (!isEditing) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Smart Dynamic Playlist',
                  style: TextStyle(
                      color: EverforestColors.fg,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Auto-updates based on rules and genre tags',
                  style:
                      TextStyle(color: EverforestColors.grey, fontSize: 11),
                ),
                value: _isSmart,
                activeThumbColor: EverforestColors.green,
                onChanged: (val) => setState(() => _isSmart = val),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: EverforestColors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: EverforestColors.green,
            foregroundColor: EverforestColors.bg0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: EverforestColors.bg0),
                )
              : Text(isEditing ? 'Save Changes' : 'Create Playlist'),
        ),
      ],
    );
  }
}
