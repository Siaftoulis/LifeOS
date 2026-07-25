import 'package:flutter/material.dart';
import '../../theme/everforest_colors.dart';

class SlashCommandItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String markdownSnippet;

  const SlashCommandItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.markdownSnippet,
  });
}

class ZenSlashMenu extends StatelessWidget {
  final String query;
  final int selectedIndex;
  final Function(SlashCommandItem) onSelected;
  final List<SlashCommandItem> filteredItems;

  const ZenSlashMenu({
    super.key,
    required this.query,
    required this.selectedIndex,
    required this.onSelected,
    required this.filteredItems,
  });

  static const List<SlashCommandItem> allCommands = [
    SlashCommandItem(
      title: 'Heading 1',
      subtitle: 'Big section heading',
      icon: Icons.h_mobiledata,
      markdownSnippet: '# ',
    ),
    SlashCommandItem(
      title: 'Heading 2',
      subtitle: 'Medium section heading',
      icon: Icons.h_mobiledata,
      markdownSnippet: '## ',
    ),
    SlashCommandItem(
      title: 'Heading 3',
      subtitle: 'Small section heading',
      icon: Icons.h_mobiledata,
      markdownSnippet: '### ',
    ),
    SlashCommandItem(
      title: 'To-do List',
      subtitle: 'Track tasks with checkboxes',
      icon: Icons.check_box_outlined,
      markdownSnippet: '- [ ] ',
    ),
    SlashCommandItem(
      title: 'Bulleted List',
      subtitle: 'Create a simple list',
      icon: Icons.format_list_bulleted,
      markdownSnippet: '- ',
    ),
    SlashCommandItem(
      title: 'Numbered List',
      subtitle: 'Create an ordered list',
      icon: Icons.format_list_numbered,
      markdownSnippet: '1. ',
    ),
    SlashCommandItem(
      title: 'Quote',
      subtitle: 'Capture a quote',
      icon: Icons.format_quote,
      markdownSnippet: '> ',
    ),
    SlashCommandItem(
      title: 'Code Block',
      subtitle: 'Write code snippets',
      icon: Icons.code,
      markdownSnippet: '```\n\n```',
    ),
    SlashCommandItem(
      title: 'Divider',
      subtitle: 'Visually divide text',
      icon: Icons.horizontal_rule,
      markdownSnippet: '---\n',
    ),
    SlashCommandItem(
      title: 'Table',
      subtitle: 'Insert a markdown table',
      icon: Icons.table_chart,
      markdownSnippet: '| Column 1 | Column 2 |\n|----------|----------|\n| Row 1    |          |',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (filteredItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 300,
      constraints: const BoxConstraints(maxHeight: 350),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EverforestColors.bg2, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: EverforestColors.bg2)),
            ),
            child: Text(
              'Basic blocks',
              style: TextStyle(color: EverforestColors.grey, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final isSelected = index == selectedIndex;
                
                return InkWell(
                  onTap: () => onSelected(item),
                  child: Container(
                    color: isSelected ? EverforestColors.bg2 : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: EverforestColors.bg0,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: EverforestColors.bg2),
                          ),
                          child: Icon(item.icon, size: 20, color: EverforestColors.fg),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.w600)),
                              Text(item.subtitle, style: const TextStyle(color: EverforestColors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
