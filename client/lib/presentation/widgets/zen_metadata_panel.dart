import 'package:flutter/material.dart';
import '../../core/obsidian/frontmatter_service.dart';
import '../../theme/everforest_colors.dart';

class ZenMetadataPanel extends StatefulWidget {
  final String? rawFrontmatter;
  final ValueChanged<String> onFrontmatterChanged;

  const ZenMetadataPanel({
    super.key,
    this.rawFrontmatter,
    required this.onFrontmatterChanged,
  });

  @override
  State<ZenMetadataPanel> createState() => _ZenMetadataPanelState();
}

class _ZenMetadataPanelState extends State<ZenMetadataPanel> {
  Map<String, dynamic> _properties = {};
  final TextEditingController _newTagCtr = TextEditingController();

  @override
  void initState() {
    super.initState();
    _parseCurrentFrontmatter();
  }

  @override
  void didUpdateWidget(ZenMetadataPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rawFrontmatter != widget.rawFrontmatter) {
      _parseCurrentFrontmatter();
    }
  }

  @override
  void dispose() {
    _newTagCtr.dispose();
    super.dispose();
  }

  void _parseCurrentFrontmatter() {
    if (widget.rawFrontmatter != null) {
      _properties = Map<String, dynamic>.from(
        FrontmatterService.parseFrontmatter(widget.rawFrontmatter!),
      );
    } else {
      _properties = {};
    }
  }

  void _saveProperties() {
    final updatedContent = FrontmatterService.updateFrontmatter(
      widget.rawFrontmatter ?? '---\n---',
      _properties,
    );
    final extracted = FrontmatterService.extractBodyAndFrontmatter(updatedContent);
    if (extracted.frontmatter != null) {
      widget.onFrontmatterChanged(extracted.frontmatter!);
    }
  }

  void _addTag(String tag) {
    final cleanTag = tag.trim().replaceAll('#', '');
    if (cleanTag.isEmpty) return;

    final tags = List<String>.from(_properties['tags'] ?? []);
    if (!tags.contains(cleanTag)) {
      tags.add(cleanTag);
      _properties['tags'] = tags;
      _saveProperties();
      _newTagCtr.clear();
      setState(() {});
    }
  }

  void _removeTag(String tag) {
    final tags = List<String>.from(_properties['tags'] ?? []);
    tags.remove(tag);
    if (tags.isEmpty) {
      _properties.remove('tags');
    } else {
      _properties['tags'] = tags;
    }
    _saveProperties();
    setState(() {});
  }

  void _updateProperty(String key, dynamic value) {
    _properties[key] = value;
    _saveProperties();
    setState(() {});
  }

  void _removeProperty(String key) {
    _properties.remove(key);
    _saveProperties();
    setState(() {});
  }

  void _showAddPropertyDialog() {
    final keyCtr = TextEditingController();
    final valCtr = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: EverforestColors.bg1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text('Add Metadata Property', style: TextStyle(color: EverforestColors.fg)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyCtr,
                style: const TextStyle(color: EverforestColors.fg),
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Property Key (e.g. author, status)',
                  hintStyle: TextStyle(color: EverforestColors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valCtr,
                style: const TextStyle(color: EverforestColors.fg),
                decoration: const InputDecoration(
                  hintText: 'Value',
                  hintStyle: TextStyle(color: EverforestColors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: EverforestColors.grey)),
            ),
            TextButton(
              onPressed: () {
                final k = keyCtr.text.trim();
                final v = valCtr.text.trim();
                if (k.isNotEmpty) {
                  _updateProperty(k, v);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Add', style: TextStyle(color: EverforestColors.green)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final systemKeys = {'id', 'updated_at', 'synced_at'};
    final tagsList = List<String>.from(_properties['tags'] ?? []);
    final customEntries = _properties.entries.where((e) => !systemKeys.contains(e.key) && e.key != 'tags').toList();

    return Container(
      color: EverforestColors.bg1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune, color: EverforestColors.green, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'METADATA INSPECTOR',
                      style: TextStyle(
                        color: EverforestColors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: EverforestColors.green, size: 18),
                  tooltip: 'Add Property',
                  onPressed: _showAddPropertyDialog,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: EverforestColors.bg2),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // System Info Section
                const Text('System Metadata', style: TextStyle(color: EverforestColors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: EverforestColors.bg0,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: EverforestColors.bg2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID: ${_properties['id'] ?? 'Not assigned'}', style: const TextStyle(color: EverforestColors.fg, fontSize: 11, fontFamily: 'JetBrainsMono')),
                      const SizedBox(height: 4),
                      Text('Updated: ${_properties['updated_at'] ?? 'Never'}', style: const TextStyle(color: EverforestColors.grey, fontSize: 10)),
                      Text('Synced: ${_properties['synced_at'] ?? 'null'}', style: const TextStyle(color: EverforestColors.grey, fontSize: 10)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tags Section
                const Text('Tags', style: TextStyle(color: EverforestColors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...tagsList.map((tag) => Chip(
                      label: Text('#$tag', style: const TextStyle(color: EverforestColors.green, fontSize: 11)),
                      backgroundColor: EverforestColors.green.withValues(alpha: 0.15),
                      deleteIcon: const Icon(Icons.close, size: 12, color: EverforestColors.green),
                      onDeleted: () => _removeTag(tag),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    )),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newTagCtr,
                        style: const TextStyle(color: EverforestColors.fg, fontSize: 12),
                        decoration: const InputDecoration(
                          hintText: 'Add tag...',
                          hintStyle: TextStyle(color: EverforestColors.grey, fontSize: 12),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green)),
                        ),
                        onSubmitted: _addTag,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, size: 16, color: EverforestColors.green),
                      onPressed: () => _addTag(_newTagCtr.text),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Custom Properties Section
                const Text('Custom Properties', style: TextStyle(color: EverforestColors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                if (customEntries.isEmpty)
                  const Text('No custom properties added.', style: TextStyle(color: EverforestColors.grey, fontSize: 11, fontStyle: FontStyle.italic))
                else
                  ...customEntries.map((entry) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: EverforestColors.bg0,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Text('${entry.key}:', style: const TextStyle(color: EverforestColors.purple, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${entry.value}',
                            style: const TextStyle(color: EverforestColors.fg, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 14, color: EverforestColors.grey),
                          onPressed: () => _removeProperty(entry.key),
                          splashRadius: 14,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  )).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
