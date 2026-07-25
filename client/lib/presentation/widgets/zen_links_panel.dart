import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/obsidian/vault_scanner.dart';
import '../../theme/everforest_colors.dart';

class LinkSnippet {
  final String notePath;
  final String noteName;
  final String snippet;
  final int lineNumber;

  LinkSnippet({
    required this.notePath,
    required this.noteName,
    required this.snippet,
    required this.lineNumber,
  });
}

class ZenLinksPanel extends StatefulWidget {
  final VaultScanner scanner;
  final String? activeFilePath;
  final ValueChanged<String> onNoteSelected;

  const ZenLinksPanel({
    super.key,
    required this.scanner,
    this.activeFilePath,
    required this.onNoteSelected,
  });

  @override
  State<ZenLinksPanel> createState() => _ZenLinksPanelState();
}

class _ZenLinksPanelState extends State<ZenLinksPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _filterCtr = TextEditingController();

  List<LinkSnippet> _backlinks = [];
  List<LinkSnippet> _outgoingLinks = [];
  List<LinkSnippet> _unlinkedMentions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _filterCtr.addListener(() => setState(() {}));
    widget.scanner.addListener(_analyzeLinks);
    _analyzeLinks();
  }

  @override
  void didUpdateWidget(ZenLinksPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeFilePath != widget.activeFilePath) {
      _analyzeLinks();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _filterCtr.dispose();
    widget.scanner.removeListener(_analyzeLinks);
    super.dispose();
  }

  void _analyzeLinks() {
    if (widget.activeFilePath == null) {
      setState(() {
        _backlinks = [];
        _outgoingLinks = [];
        _unlinkedMentions = [];
      });
      return;
    }

    final activePath = widget.activeFilePath!;
    final activeTitle = activePath.split(RegExp(r'[/\\]')).last.replaceAll('.md', '');

    final newBacklinks = <LinkSnippet>[];
    final newOutgoing = <LinkSnippet>[];
    final newUnlinked = <LinkSnippet>[];

    // 1. Process Backlinks
    final incomingPaths = widget.scanner.graph.backlinks[activePath] ?? [];
    for (final path in incomingPaths) {
      final name = path.split(RegExp(r'[/\\]')).last.replaceAll('.md', '');
      final snippet = _extractSnippet(path, activeTitle);
      newBacklinks.add(LinkSnippet(
        notePath: path,
        noteName: name,
        snippet: snippet.snippet,
        lineNumber: snippet.lineNum,
      ));
    }

    // 2. Process Outgoing Links
    final outgoingPaths = widget.scanner.graph.links[activePath] ?? [];
    for (final path in outgoingPaths) {
      final name = path.split(RegExp(r'[/\\]')).last.replaceAll('.md', '');
      newOutgoing.add(LinkSnippet(
        notePath: path,
        noteName: name,
        snippet: 'Linked via [[$name]]',
        lineNumber: 1,
      ));
    }

    // 3. Process Unlinked Mentions
    if (activeTitle.length > 2) {
      for (final entry in widget.scanner.nodes.entries) {
        if (entry.key == activePath) continue;
        if (incomingPaths.contains(entry.key)) continue;

        try {
          final file = File(entry.key);
          if (!file.existsSync()) continue;
          final lines = file.readAsLinesSync();
          for (int i = 0; i < lines.length; i++) {
            final line = lines[i];
            if (line.contains(activeTitle) && !line.contains('[[$activeTitle]]')) {
              final name = entry.key.split(RegExp(r'[/\\]')).last.replaceAll('.md', '');
              newUnlinked.add(LinkSnippet(
                notePath: entry.key,
                noteName: name,
                snippet: line.trim(),
                lineNumber: i + 1,
              ));
              break;
            }
          }
        } catch (_) {}
      }
    }

    setState(() {
      _backlinks = newBacklinks;
      _outgoingLinks = newOutgoing;
      _unlinkedMentions = newUnlinked;
    });
  }

  ({String snippet, int lineNum}) _extractSnippet(String path, String targetTitle) {
    try {
      final file = File(path);
      if (!file.existsSync()) return (snippet: 'Mentioned note', lineNum: 1);
      final lines = file.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains(targetTitle)) {
          return (snippet: lines[i].trim(), lineNum: i + 1);
        }
      }
    } catch (_) {}
    return (snippet: 'Linked note', lineNum: 1);
  }

  void _convertToWikilink(LinkSnippet snippet) {
    final activeTitle = widget.activeFilePath?.split(RegExp(r'[/\\]')).last.replaceAll('.md', '') ?? '';
    if (activeTitle.isEmpty) return;

    try {
      final file = File(snippet.notePath);
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        final updated = content.replaceAll(activeTitle, '[[$activeTitle]]');
        file.writeAsStringSync(updated);
        _analyzeLinks();
      }
    } catch (e) {
      debugPrint('Error converting unlinked mention to wikilink: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _filterCtr.text.toLowerCase();

    final filteredBacklinks = _backlinks.where((s) => s.noteName.toLowerCase().contains(query) || s.snippet.toLowerCase().contains(query)).toList();
    final filteredOutgoing = _outgoingLinks.where((s) => s.noteName.toLowerCase().contains(query)).toList();
    final filteredUnlinked = _unlinkedMentions.where((s) => s.noteName.toLowerCase().contains(query) || s.snippet.toLowerCase().contains(query)).toList();

    return Container(
      color: EverforestColors.bg1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: EverforestColors.green,
            labelColor: EverforestColors.green,
            unselectedLabelColor: EverforestColors.grey,
            labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Backlinks (${_backlinks.length})'),
              Tab(text: 'Outgoing (${_outgoingLinks.length})'),
              Tab(text: 'Unlinked (${_unlinkedMentions.length})'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _filterCtr,
              style: const TextStyle(color: EverforestColors.fg, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Filter links...',
                hintStyle: const TextStyle(color: EverforestColors.grey, fontSize: 12),
                prefixIcon: const Icon(Icons.search, size: 14, color: EverforestColors.grey),
                isDense: true,
                filled: true,
                fillColor: EverforestColors.bg0,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSnippetList(filteredBacklinks, isUnlinked: false),
                _buildSnippetList(filteredOutgoing, isUnlinked: false),
                _buildSnippetList(filteredUnlinked, isUnlinked: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnippetList(List<LinkSnippet> list, {required bool isUnlinked}) {
    if (list.isEmpty) {
      return const Center(
        child: Text(
          'No links found',
          style: TextStyle(color: EverforestColors.grey, fontSize: 12, fontStyle: FontStyle.italic),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: EverforestColors.bg2),
      itemBuilder: (context, index) {
        final item = list[index];
        return InkWell(
          onTap: () => widget.onNoteSelected(item.notePath),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description_outlined, size: 14, color: EverforestColors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.noteName,
                        style: const TextStyle(
                          color: EverforestColors.fg,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isUnlinked)
                      TextButton.icon(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 24)),
                        onPressed: () => _convertToWikilink(item),
                        icon: const Icon(Icons.link, size: 12, color: EverforestColors.purple),
                        label: const Text('Link', style: TextStyle(color: EverforestColors.purple, fontSize: 10)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.snippet,
                  style: const TextStyle(color: EverforestColors.grey, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
