import 'package:flutter/material.dart';
import '../../../../../core/domain_repositories.dart';
import '../../../../../theme/app_skin_manager.dart';

class CreatePlaylistDialog extends StatefulWidget {
  const CreatePlaylistDialog({
    super.key,
    this.initialPlaylist,
    this.initialSmartType,
    this.initialSmartConfig,
    this.initialName,
  });

  final Playlist? initialPlaylist;
  final String? initialSmartType;
  final String? initialSmartConfig;
  final String? initialName;

  static Future<Playlist?> show(
    BuildContext context, {
    Playlist? initialPlaylist,
    String? initialSmartType,
    String? initialSmartConfig,
    String? initialName,
  }) {
    return showDialog<Playlist>(
      context: context,
      builder: (_) => CreatePlaylistDialog(
        initialPlaylist: initialPlaylist,
        initialSmartType: initialSmartType,
        initialSmartConfig: initialSmartConfig,
        initialName: initialName,
      ),
    );
  }

  @override
  State<CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends State<CreatePlaylistDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _smartConfigCtrl;
  bool _isSmart = false;
  String _smartType = 'genre';
  bool _isSubmitting = false;

  static const List<String> _popularGenres = [
    'Rock',
    'Pop',
    'Metal',
    'Electronic',
    'Synthwave',
    'Hip Hop',
    'Jazz',
    'Classical',
    'Soundtrack',
    'Acoustic',
    'Indie',
  ];

  static const List<String> _decades = [
    '1960s',
    '1970s',
    '1980s',
    '1990s',
    '2000s',
    '2010s',
    '2020s',
  ];

  @override
  void initState() {
    super.initState();
    _isSmart = widget.initialPlaylist?.isSmart ?? (widget.initialSmartType != null);
    _smartType = widget.initialPlaylist?.smartType.isNotEmpty == true
        ? widget.initialPlaylist!.smartType
        : (widget.initialSmartType ?? 'genre');

    final initialConfig = widget.initialPlaylist?.smartConfig.isNotEmpty == true
        ? widget.initialPlaylist!.smartConfig
        : (widget.initialSmartConfig ?? (_smartType == 'genre' ? 'Rock' : ''));

    _smartConfigCtrl = TextEditingController(text: initialConfig);

    final initialTitle = widget.initialPlaylist?.name ??
        (widget.initialName ?? (_isSmart ? _suggestedName(_smartType, initialConfig) : ''));
    _titleCtrl = TextEditingController(text: initialTitle);
    _descCtrl = TextEditingController(text: widget.initialPlaylist?.description ?? '');
  }

  String _suggestedName(String type, String config) {
    switch (type) {
      case 'genre':
        return config.isNotEmpty ? '$config Mix' : 'Genre Mix';
      case 'decade':
        return config.isNotEmpty ? '$config Hits' : 'Decade Mix';
      case 'folder':
        return config.isNotEmpty ? 'Folder: $config' : 'Folder Mix';
      case 'recently_added':
        return 'Recently Added';
      case 'most_played':
        return 'Heavy Rotation';
      default:
        return 'Smart Mix';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _smartConfigCtrl.dispose();
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
        final config = (_smartType == 'recently_added' || _smartType == 'most_played')
            ? ''
            : _smartConfigCtrl.text.trim();

        final created = await MusicRepository.instance.createPlaylist(
          PlaylistCreate(
            name: title,
            description: _descCtrl.text.trim(),
            isSmart: _isSmart,
            smartType: _isSmart ? _smartType : '',
            smartConfig: _isSmart ? config : '',
          ),
        );
        if (mounted && created != null) {
          Navigator.pop(context, created);
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _onSelectSmartType(String type) {
    setState(() {
      _smartType = type;
      if (type == 'genre' && _smartConfigCtrl.text.isEmpty) {
        _smartConfigCtrl.text = 'Rock';
      } else if (type == 'decade' && _smartConfigCtrl.text.isEmpty) {
        _smartConfigCtrl.text = '1980s';
      }
      _titleCtrl.text = _suggestedName(type, _smartConfigCtrl.text.trim());
    });
  }

  void _onSelectConfig(String config) {
    setState(() {
      _smartConfigCtrl.text = config;
      _titleCtrl.text = _suggestedName(_smartType, config);
    });
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
              isEditing
                  ? Icons.edit_rounded
                  : (_isSmart ? Icons.auto_awesome_rounded : Icons.playlist_add_rounded),
              color: _isSmart ? skin.yellow : skin.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isEditing
                ? 'Edit Playlist'
                : (_isSmart ? 'New Smart Mix' : 'New Playlist'),
            style: TextStyle(
              color: skin.fg,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleCtrl,
                autofocus: !isEditing,
                style: TextStyle(color: skin.fg),
                decoration: InputDecoration(
                  labelText: 'Playlist Name',
                  labelStyle: TextStyle(color: skin.textMuted),
                  hintText: 'e.g. Midnight Grooves, 80s Hits',
                  hintStyle: TextStyle(color: skin.textMuted, fontSize: 13),
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
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: skin.bg0,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isSmart ? skin.yellow.withValues(alpha: 0.3) : skin.bg2,
                    ),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: _isSmart ? skin.yellow : skin.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Smart Dynamic Playlist',
                          style: TextStyle(
                            color: skin.fg,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      'Auto-updates matching songs based on metadata tags & rules',
                      style: TextStyle(color: skin.textMuted, fontSize: 11),
                    ),
                    value: _isSmart,
                    activeThumbColor: skin.yellow,
                    onChanged: (val) {
                      setState(() {
                        _isSmart = val;
                        if (val && _titleCtrl.text.isEmpty) {
                          _titleCtrl.text = _suggestedName(_smartType, _smartConfigCtrl.text.trim());
                        }
                      });
                    },
                  ),
                ),
                if (_isSmart) ...[
                  const SizedBox(height: 16),
                  Text(
                    'RULE TYPE',
                    style: TextStyle(
                      color: skin.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _typeChip('genre', 'Genre / Tag', Icons.music_note_rounded, skin),
                      _typeChip('decade', 'Era / Decade', Icons.calendar_month_rounded, skin),
                      _typeChip('folder', 'Local Folder', Icons.folder_special_rounded, skin),
                      _typeChip('recently_added', 'Recent', Icons.schedule_rounded, skin),
                      _typeChip('most_played', 'Top Played', Icons.local_fire_department_rounded, skin),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_smartType == 'genre') ...[
                    Text(
                      'Select or type a genre filter:',
                      style: TextStyle(color: skin.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _popularGenres.map((g) {
                        final isSelected = _smartConfigCtrl.text.trim().toLowerCase() == g.toLowerCase();
                        return ChoiceChip(
                          label: Text(g),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? skin.accentContrast : skin.fg,
                          ),
                          selected: isSelected,
                          selectedColor: skin.accent,
                          backgroundColor: skin.bg0,
                          onSelected: (_) => _onSelectConfig(g),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _smartConfigCtrl,
                      style: TextStyle(color: skin.fg, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Genre / Style keyword',
                        labelStyle: TextStyle(color: skin.textMuted),
                        hintText: 'e.g. Rock, Synthwave, Soundtracks',
                        hintStyle: TextStyle(color: skin.textMuted, fontSize: 12),
                        filled: true,
                        fillColor: skin.bg0,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty) {
                          _titleCtrl.text = _suggestedName('genre', val);
                        }
                      },
                    ),
                  ] else if (_smartType == 'decade') ...[
                    Text(
                      'Select era or decade:',
                      style: TextStyle(color: skin.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _decades.map((d) {
                        final isSelected = _smartConfigCtrl.text.trim() == d;
                        return ChoiceChip(
                          label: Text(d),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? skin.accentContrast : skin.fg,
                          ),
                          selected: isSelected,
                          selectedColor: skin.accent,
                          backgroundColor: skin.bg0,
                          onSelected: (_) => _onSelectConfig(d),
                        );
                      }).toList(),
                    ),
                  ] else if (_smartType == 'folder') ...[
                    Text(
                      'Filter local tracks by path or folder name:',
                      style: TextStyle(color: skin.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _smartConfigCtrl,
                      style: TextStyle(color: skin.fg, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Folder keyword or path',
                        labelStyle: TextStyle(color: skin.textMuted),
                        hintText: 'e.g. Soundtracks, Hi-Res, FLAC',
                        hintStyle: TextStyle(color: skin.textMuted, fontSize: 12),
                        filled: true,
                        fillColor: skin.bg0,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty) {
                          _titleCtrl.text = _suggestedName('folder', val);
                        }
                      },
                    ),
                  ] else if (_smartType == 'recently_added') ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: skin.bg0,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: skin.bg2),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 18, color: skin.accent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Auto-includes up to 100 newest downloaded and local imported tracks, sorted by addition date.',
                              style: TextStyle(color: skin.textMuted, fontSize: 11.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_smartType == 'most_played') ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: skin.bg0,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: skin.bg2),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_fire_department_rounded, size: 18, color: skin.yellow),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Auto-includes top 100 most played tracks across your library.',
                              style: TextStyle(color: skin.textMuted, fontSize: 11.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: skin.textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _isSmart ? skin.yellow : skin.accent,
            foregroundColor: _isSmart ? Colors.black : skin.accentContrast,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _isSmart ? Colors.black : skin.accentContrast,
                  ),
                )
              : Text(
                  isEditing
                      ? 'Save Changes'
                      : (_isSmart ? 'Create Smart Mix' : 'Create Playlist'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  Widget _typeChip(String type, String label, IconData icon, dynamic skin) {
    final isSelected = _smartType == type;
    return InkWell(
      onTap: () => _onSelectSmartType(type),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? skin.yellow.withValues(alpha: 0.18) : skin.bg0,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? skin.yellow : skin.bg2,
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? skin.yellow : skin.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? skin.yellow : skin.fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
