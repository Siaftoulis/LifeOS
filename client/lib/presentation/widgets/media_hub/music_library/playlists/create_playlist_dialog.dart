import 'package:flutter/material.dart';
import '../../../../../core/domain_repositories.dart';
import '../../../../../theme/app_skin_manager.dart';

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
    final skin = context.skin;
    final isEditing = widget.initialPlaylist != null;
    return AlertDialog(
      backgroundColor: skin.bg1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: skin.bg2),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: skin.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isEditing ? Icons.edit_rounded : Icons.playlist_add_rounded,
              color: skin.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isEditing ? 'Edit Playlist' : 'New Playlist',
            style: TextStyle(
              color: skin.fg,
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
              style: TextStyle(color: skin.fg),
              decoration: InputDecoration(
                labelText: 'Playlist Name',
                labelStyle: TextStyle(color: skin.textMuted),
                hintText: 'e.g. Midnight Grooves, Study Session',
                hintStyle:
                    TextStyle(color: skin.textMuted, fontSize: 13),
                filled: true,
                fillColor: skin.bg0,
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
              style: TextStyle(color: skin.fg),
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                labelStyle: TextStyle(color: skin.textMuted),
                filled: true,
                fillColor: skin.bg0,
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
                title: Text(
                  'Smart Dynamic Playlist',
                  style: TextStyle(
                      color: skin.fg,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Auto-updates based on rules and genre tags',
                  style:
                      TextStyle(color: skin.textMuted, fontSize: 11),
                ),
                value: _isSmart,
                activeThumbColor: skin.accent,
                onChanged: (val) => setState(() => _isSmart = val),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: TextStyle(color: skin.textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: skin.accent,
            foregroundColor: skin.accentContrast,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: skin.accentContrast),
                )
              : Text(isEditing ? 'Save Changes' : 'Create Playlist'),
        ),
      ],
    );
  }
}
