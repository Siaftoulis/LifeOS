import 'dart:async';
import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../core/obsidian/config_parser.dart';
import '../../theme/everforest_colors.dart';

class MarkdownEditingController extends TextEditingController {
  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    List<TextSpan> spans = [];
    final text = this.text;
    
    final RegExp syntaxExp = RegExp(r'(\*\*.*?\*\*)|(# .*)');
    int lastMatchEnd = 0;
    
    for (final match in syntaxExp.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start), style: style));
      }
      spans.add(TextSpan(
        text: match.group(0), 
        style: style?.copyWith(
          color: EverforestColors.green,
          fontWeight: FontWeight.bold,
        ),
      ));
      lastMatchEnd = match.end;
    }
    
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd), style: style));
    }
    
    return TextSpan(children: spans, style: style);
  }
}

class ZenWorkspace extends StatefulWidget {
  const ZenWorkspace({super.key});
  @override 
  State<ZenWorkspace> createState() => _ZenWorkspaceState();
}

class _ZenWorkspaceState extends State<ZenWorkspace> {
  late final MarkdownEditingController _noteCtr;
  Timer? _debounce;
  ObsidianConfig? _config;
  
  bool _leftSidebarOpen = true;
  bool _rightSidebarOpen = false; // Closed by default to show split pane
  
  // Tablet/Desktop specific states
  bool _isLeftSidebarPinned = true;
  bool _isSplitPane = true;
  int _activeTabIndex = 0;
  final List<String> _tabs = ['Writing is telepathy', 'Everything is a remix', 'Cross the chasm'];

  final Color _accentColor = const Color(0xFF7E57C2);

  @override 
  void initState() { 
    super.initState(); 
    _noteCtr = _buildEditorController();
    _loadInitialNote(); 
    _loadConfig();
  }

  MarkdownEditingController _buildEditorController() {
    return MarkdownEditingController();
  }
  
  Future<void> _loadConfig() async {
    final parser = ConfigParser('vault');
    final cfg = await parser.parseConfig();
    if (mounted) setState(() => _config = cfg);
  }

  @override 
  void dispose() { 
    _debounce?.cancel(); 
    _noteCtr.dispose(); 
    super.dispose(); 
  }

  Future<void> _loadInitialNote() async {
    final res = await ApiClient.instance.post('/api/obsidian/load', {});
    if (res['content'] != null && mounted) setState(() => _noteCtr.text = res['content']);
  }
  
  void _showSettingsModal(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      showDialog(
        context: context,
        useSafeArea: false,
        builder: (context) {
          return const MobileSettingsDialog();
        }
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: EverforestColors.bg1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: SizedBox(
            width: 800,
            height: 600,
            child: Row(
              children: [
                Container(
                  width: 200,
                  decoration: const BoxDecoration(
                    color: EverforestColors.bg2,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('Options', style: TextStyle(color: EverforestColors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      _buildSettingsNavItem('Mobile', false),
                      _buildSettingsNavItem('Editor', false),
                      _buildSettingsNavItem('Files & Links', false),
                      _buildSettingsNavItem('Appearance', true),
                      _buildSettingsNavItem('Hotkeys', false),
                      _buildSettingsNavItem('About', false),
                      const Divider(color: EverforestColors.bg0),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('Core plugins', style: TextStyle(color: EverforestColors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      _buildSettingsNavItem('Backlinks', false),
                      _buildSettingsNavItem('Command palette', false),
                      _buildSettingsNavItem('Daily notes', false),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Appearance', style: TextStyle(color: EverforestColors.fg, fontSize: 20, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.close, color: EverforestColors.grey), 
                              onPressed: () => Navigator.of(context).pop(),
                              splashRadius: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Base color scheme', style: TextStyle(color: EverforestColors.fg, fontSize: 14)),
                                Text('Choose Obsidian\'s default color scheme.', style: TextStyle(color: EverforestColors.grey, fontSize: 12)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: EverforestColors.bg2, borderRadius: BorderRadius.circular(4)),
                              child: const Text('Dark  ▼', style: TextStyle(color: EverforestColors.fg, fontSize: 14)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: EverforestColors.bg2),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Accent color', style: TextStyle(color: EverforestColors.fg, fontSize: 14)),
                                Text('Choose the accent color used throughout the app.', style: TextStyle(color: EverforestColors.grey, fontSize: 12)),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.refresh, color: EverforestColors.grey, size: 20),
                                const SizedBox(width: 16),
                                Container(width: 32, height: 32, decoration: BoxDecoration(color: _accentColor, shape: BoxShape.circle)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: EverforestColors.bg2),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Themes', style: TextStyle(color: EverforestColors.fg, fontSize: 14)),
                                Text('Manage installed themes and browse community themes.', style: TextStyle(color: EverforestColors.grey, fontSize: 12)),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(color: EverforestColors.bg2, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('Default  ▼', style: TextStyle(color: EverforestColors.fg, fontSize: 14)),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(color: _accentColor, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('Manage', style: TextStyle(color: Colors.white, fontSize: 14)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsNavItem(String title, bool isActive) {
    return Material(
      color: isActive ? _accentColor.withValues(alpha: 0.2) : Colors.transparent,
      child: ListTile(
        title: Text(title, style: TextStyle(color: isActive ? _accentColor : EverforestColors.fg, fontSize: 14)),
        dense: true,
        hoverColor: Colors.white10,
        onTap: () {},
      ),
    );
  }

  Widget _buildHoverIconButton(IconData icon, String tooltip, VoidCallback onPressed, {Color? color}) {
    return IconButton(
      icon: Icon(icon, color: color ?? EverforestColors.grey), 
      tooltip: tooltip, 
      onPressed: onPressed,
      hoverColor: Colors.white10,
      splashRadius: 20,
    );
  }

  Widget _buildRibbon() {
    return Container(
      width: 48,
      color: EverforestColors.bg1,
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildHoverIconButton(Icons.hub, 'Open Graph', () {}),
          _buildHoverIconButton(Icons.today, 'Daily Note', () {}),
          _buildHoverIconButton(Icons.folder_shared, 'Switch Vault', () {}),
          const Spacer(),
          _buildHoverIconButton(Icons.settings, 'Settings', () => _showSettingsModal(context)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMobileRibbon() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: EverforestColors.bg1,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildHoverIconButton(Icons.hub, 'Open Graph', () {}),
          _buildHoverIconButton(Icons.today, 'Daily Note', () {}),
          _buildHoverIconButton(Icons.folder_shared, 'Switch Vault', () {}),
          _buildHoverIconButton(Icons.settings, 'Settings', () => _showSettingsModal(context)),
        ],
      ),
    );
  }
  
  Widget _buildLeftSidebar() {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: EverforestColors.bg1, 
        border: Border(right: BorderSide(color: EverforestColors.bg2, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Text('Notes', style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, color: EverforestColors.grey, size: 20),
                  ],
                ),
                _buildHoverIconButton(
                  _isLeftSidebarPinned ? Icons.push_pin : Icons.push_pin_outlined, 
                  'Toggle Pin', 
                  () => setState(() {
                    _isLeftSidebarPinned = !_isLeftSidebarPinned;
                    if (!_isLeftSidebarPinned) _leftSidebarOpen = false;
                  }),
                  color: _isLeftSidebarPinned ? _accentColor : EverforestColors.grey,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.folder_open, color: EverforestColors.grey, size: 18),
                    SizedBox(width: 8),
                    Text('Files', style: TextStyle(color: EverforestColors.fg, fontSize: 14)),
                  ],
                ),
                Row(
                  children: [
                    _buildHoverIconButton(Icons.swap_vert, 'Sort', () {}),
                    _buildHoverIconButton(Icons.post_add, 'New File', () {}),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildTreeItem('Clippings', true),
                _buildTreeItem('Daily', true),
                _buildTreeItem('Ideas', true, isExpanded: true),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Material(
                    color: Colors.white10,
                    child: ListTile(
                      title: const Text('Writing is telepathy', style: TextStyle(color: EverforestColors.fg, fontSize: 13)),
                      dense: true,
                      onTap: () {},
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                _buildTreeItem('Projects', true),
                _buildTreeItem('References', true),
                const SizedBox(height: 16),
                _buildTreeItem('1,000 true fans', false),
                _buildTreeItem('A company is a superorganism', false),
                _buildTreeItem('A little bit every day', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeItem(String title, bool isFolder, {bool isExpanded = false}) {
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        leading: Icon(
          isFolder ? (isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right) : Icons.description,
          color: EverforestColors.grey,
          size: 16,
        ),
        title: Text(title, style: const TextStyle(color: EverforestColors.grey, fontSize: 13)),
        dense: true,
        hoverColor: Colors.white10,
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        onTap: () {},
      ),
    );
  }
  
  Widget _buildRightSidebar({bool isMobile = false}) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('BACKLINKS', style: TextStyle(color: EverforestColors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              if (!isMobile)
                _buildHoverIconButton(Icons.close, 'Close', () => setState(() => _rightSidebarOpen = false)),
            ],
          ),
        ),
        Material(
          type: MaterialType.transparency,
          child: ListTile(
            title: const Text('Concepts MOC', style: TextStyle(color: EverforestColors.fg, fontSize: 13)),
            leading: const Icon(Icons.link, color: EverforestColors.grey, size: 16),
            dense: true,
            hoverColor: Colors.white10,
            onTap: () {},
          ),
        ),
      ],
    );

    if (isMobile) {
      return Container(
        color: EverforestColors.bg1,
        child: content,
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _rightSidebarOpen ? 260 : 0,
      color: EverforestColors.bg1,
      child: _rightSidebarOpen ? content : const SizedBox.shrink(),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 40,
      color: EverforestColors.bg0,
      child: Row(
        children: [
          if (!_isLeftSidebarPinned)
            _buildHoverIconButton(Icons.menu, 'Menu', () => setState(() => _leftSidebarOpen = !_leftSidebarOpen)),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              itemBuilder: (context, index) {
                bool isActive = _activeTabIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _activeTabIndex = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isActive ? EverforestColors.bg0 : EverforestColors.bg1,
                      border: Border(
                        top: BorderSide(color: isActive ? _accentColor : Colors.transparent, width: 2),
                        right: const BorderSide(color: EverforestColors.bg2, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.description, color: isActive ? _accentColor : EverforestColors.grey, size: 14),
                        const SizedBox(width: 8),
                        Text(_tabs[index], style: TextStyle(color: isActive ? EverforestColors.fg : EverforestColors.grey, fontSize: 13)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close, size: 14, color: EverforestColors.grey),
                          onPressed: () {},
                          splashRadius: 16,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildHoverIconButton(Icons.add, 'New tab', () {}),
          _buildHoverIconButton(Icons.keyboard_arrow_down, 'More tabs', () {}),
          _buildHoverIconButton(Icons.vertical_split, 'Split Right', () => setState(() => _isSplitPane = !_isSplitPane)),
          _buildHoverIconButton(Icons.menu_open, 'Toggle Backlinks', () => setState(() => _rightSidebarOpen = !_rightSidebarOpen)),
        ],
      ),
    );
  }

  Widget _buildSplitPane() {
    return Container(
      width: 450,
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: EverforestColors.bg2, width: 1)),
        color: EverforestColors.bg0,
      ),
      child: Column(
        children: [
          Container(
            height: 40,
            color: EverforestColors.bg0,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: EverforestColors.bg0,
                      border: Border(
                        top: BorderSide(color: _accentColor, width: 2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.description, color: _accentColor, size: 14),
                        const SizedBox(width: 8),
                        const Text('Evergreen notes turn id...', style: TextStyle(color: EverforestColors.fg, fontSize: 13)),
                        const Spacer(),
                        IconButton(icon: const Icon(Icons.close, size: 14, color: EverforestColors.grey), onPressed: () {}, splashRadius: 16, constraints: const BoxConstraints()),
                      ],
                    ),
                  ),
                ),
                _buildHoverIconButton(Icons.add, 'New tab', () {}),
                _buildHoverIconButton(Icons.close, 'Close pane', () => setState(() => _isSplitPane = false)),
              ],
            ),
          ),
          const Divider(height: 1, color: EverforestColors.bg2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                _buildHoverIconButton(Icons.arrow_back, 'Back', () {}),
                _buildHoverIconButton(Icons.arrow_forward, 'Forward', () {}),
                const Spacer(),
                const Text('Ideas / Writing is telepathy', style: TextStyle(color: EverforestColors.grey, fontSize: 12)),
                const Spacer(),
                _buildHoverIconButton(Icons.edit, 'Edit', () {}, color: _accentColor),
                _buildHoverIconButton(Icons.more_vert, 'More options', () {}),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Evergreen notes turn ideas into objects that you can manipulate', style: TextStyle(color: EverforestColors.fg, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: _accentColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                        child: Text('#evergreen', style: TextStyle(color: _accentColor, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Evergreen notes allow you to think about complex ideas by building them up from smaller composable ideas.', style: TextStyle(color: EverforestColors.fg, fontSize: 14, height: 1.6)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCentralGrid({required bool isMobile}) {
    return Expanded(
      child: Container(
        color: EverforestColors.bg0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isMobile) _buildTabBar(),
            const Divider(height: 1, color: EverforestColors.bg2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  _buildHoverIconButton(Icons.arrow_back, 'Back', () {}),
                  _buildHoverIconButton(Icons.arrow_forward, 'Forward', () {}),
                  const Spacer(),
                  const Text('Ideas / Writing is telepathy', style: TextStyle(color: EverforestColors.grey, fontSize: 12)),
                  const Spacer(),
                  _buildHoverIconButton(Icons.menu_book, 'Reading view', () {}, color: _accentColor),
                  _buildHoverIconButton(Icons.more_vert, 'More options', () {}),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_config?.showLineNumber == true)
                      Container(
                        width: 40,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 16, top: 12),
                        child: Text(
                          List.generate('\n'.allMatches(_noteCtr.text).length + 1, (i) => '${i + 1}').join('\n'),
                          style: const TextStyle(color: EverforestColors.grey, fontFamily: 'JetBrainsMono', fontSize: 14),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    Expanded(
                      child: TextField(
                        controller: _noteCtr,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: const TextStyle(color: EverforestColors.fg, fontFamily: 'JetBrainsMono', fontSize: 16, height: 1.6),
                        decoration: const InputDecoration(
                          hintText: 'Start typing...', 
                          hintStyle: TextStyle(color: EverforestColors.grey), 
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(top: 12),
                        ),
                        onChanged: (text) {
                          if (_config?.showLineNumber == true) {
                            setState(() {}); 
                          }
                          if (_debounce?.isActive ?? false) _debounce!.cancel();
                          _debounce = Timer(const Duration(milliseconds: 800), () async {
                            ApiClient.instance.post('/api/obsidian/save', {'content': text});
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileActionBar(BuildContext context) {
    return Container(
      height: 56.0,
      color: EverforestColors.bg1,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.menu, color: EverforestColors.fg),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            const Expanded(
              child: Text(
                'workspace.md', 
                style: TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.menu_open, color: EverforestColors.fg),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ],
        ),
      ),
    );
  }

  @override 
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 768;

        if (isMobile) {
          return Scaffold(
            backgroundColor: EverforestColors.bg0,
            drawer: Drawer(
              width: constraints.maxWidth * 0.8,
              backgroundColor: EverforestColors.bg1,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildMobileRibbon(),
                    const Divider(height: 1, color: EverforestColors.bg1),
                    Expanded(child: _buildLeftSidebar()),
                  ],
                ),
              ),
            ),
            endDrawer: Drawer(
              width: constraints.maxWidth * 0.8,
              backgroundColor: EverforestColors.bg1,
              child: SafeArea(
                child: _buildRightSidebar(isMobile: true),
              ),
            ),
            body: Builder(
              builder: (innerContext) {
                return Column(
                  children: [
                    _buildMobileActionBar(innerContext),
                    const Divider(height: 1, color: EverforestColors.bg2),
                    _buildCentralGrid(isMobile: true),
                  ],
                );
              }
            ),
          );
        }

        // Desktop/Tablet Layout
        return Scaffold(
          backgroundColor: EverforestColors.bg0,
          body: Stack(
            children: [
              Row(
                children: [
                  _buildRibbon(),
                  if (_isLeftSidebarPinned && _leftSidebarOpen) _buildLeftSidebar(),
                  _buildCentralGrid(isMobile: false),
                  if (_isSplitPane) _buildSplitPane(),
                  _buildRightSidebar(),
                ],
              ),
              if (!_isLeftSidebarPinned && _leftSidebarOpen)
                Positioned.fill(
                  left: 48,
                  child: Row(
                    children: [
                      _buildLeftSidebar(),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _leftSidebarOpen = false),
                          child: Container(color: Colors.black45),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class MobileSettingsDialog extends StatefulWidget {
  const MobileSettingsDialog({super.key});
  @override
  State<MobileSettingsDialog> createState() => _MobileSettingsDialogState();
}

class _MobileSettingsDialogState extends State<MobileSettingsDialog> {
  String? _activeCategory;

  Widget _buildCategoryList() {
    return Scaffold(
      backgroundColor: EverforestColors.bg1,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: EverforestColors.grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Settings', style: TextStyle(color: EverforestColors.fg, fontSize: 18)),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Options', style: TextStyle(color: EverforestColors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          _buildNavItem('Mobile'),
          _buildNavItem('Editor'),
          _buildNavItem('Files & Links'),
          _buildNavItem('Appearance'),
          _buildNavItem('Hotkeys'),
          _buildNavItem('About'),
          const Divider(color: EverforestColors.bg0),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Core plugins', style: TextStyle(color: EverforestColors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          _buildNavItem('Backlinks'),
          _buildNavItem('Command palette'),
          _buildNavItem('Daily notes'),
        ],
      ),
    );
  }

  Widget _buildNavItem(String title) {
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        title: Text(title, style: const TextStyle(color: EverforestColors.fg, fontSize: 16)),
        trailing: const Icon(Icons.chevron_right, color: EverforestColors.grey),
        onTap: () {
          setState(() {
            _activeCategory = title;
          });
        },
      ),
    );
  }

  Widget _buildAppearanceCategory() {
    final _accentColor = const Color(0xFF7E57C2);
    return Scaffold(
      backgroundColor: EverforestColors.bg1,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: EverforestColors.grey),
          onPressed: () {
            setState(() {
              _activeCategory = null;
            });
          },
        ),
        title: const Text('Appearance', style: TextStyle(color: EverforestColors.fg, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Base color scheme', style: TextStyle(color: EverforestColors.fg, fontSize: 16)),
          const Text('Choose Obsidian\'s default color scheme.', style: TextStyle(color: EverforestColors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: EverforestColors.bg2, borderRadius: BorderRadius.circular(4)),
            child: const Text('Dark  ▼', style: TextStyle(color: EverforestColors.fg, fontSize: 16)),
          ),
          const SizedBox(height: 24),
          const Divider(color: EverforestColors.bg2),
          const SizedBox(height: 24),
          const Text('Accent color', style: TextStyle(color: EverforestColors.fg, fontSize: 16)),
          const Text('Choose the accent color used throughout the app.', style: TextStyle(color: EverforestColors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.refresh, color: EverforestColors.grey, size: 24),
              const SizedBox(width: 16),
              Container(width: 40, height: 40, decoration: BoxDecoration(color: _accentColor, shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: EverforestColors.bg2),
          const SizedBox(height: 24),
          const Text('Themes', style: TextStyle(color: EverforestColors.fg, fontSize: 16)),
          const Text('Manage installed themes and browse community themes.', style: TextStyle(color: EverforestColors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(color: EverforestColors.bg2, borderRadius: BorderRadius.circular(4)),
                  child: const Text('Default  ▼', style: TextStyle(color: EverforestColors.fg, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: _accentColor, borderRadius: BorderRadius.circular(4)),
                child: const Text('Manage', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_activeCategory == 'Appearance') {
      return _buildAppearanceCategory();
    }
    if (_activeCategory != null) {
      return Scaffold(
        backgroundColor: EverforestColors.bg1,
        appBar: AppBar(
          backgroundColor: EverforestColors.bg1,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: EverforestColors.grey),
            onPressed: () => setState(() => _activeCategory = null),
          ),
          title: Text(_activeCategory!, style: const TextStyle(color: EverforestColors.fg, fontSize: 18)),
        ),
        body: const Center(child: Text('Under Construction', style: TextStyle(color: EverforestColors.grey))),
      );
    }
    return _buildCategoryList();
  }
}
