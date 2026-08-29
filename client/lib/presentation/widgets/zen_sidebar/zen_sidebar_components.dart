import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

const double kZenViewHeight = 32.0;
const double kZenLevelPadding = 16.0;
const double kZenDragDividerHeight = 2.0;
const Color kZenDragHighlight = Color(0xFF00C8FF);

enum DropPosition { none, top, center, bottom }

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.showAdd,
    required this.onCollapseAll,
    required this.onAdd,
    this.expanded = true,
    this.onToggleExpanded,
  });

  final String title;
  final bool showAdd;
  final VoidCallback onCollapseAll;
  final VoidCallback onAdd;
  final bool expanded;
  final VoidCallback? onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 2),
      child: Row(
        children: [
          if (onToggleExpanded != null)
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onToggleExpanded,
              child: SizedBox(
                width: 20,
                height: 20,
                child: Transform.rotate(
                  angle: expanded ? 0 : -1.5708,
                  child: const Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: EverforestColors.grey,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 2),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onToggleExpanded,
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: EverforestColors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          if (showAdd)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              icon: const Icon(Icons.add, color: EverforestColors.grey, size: 16),
              tooltip: 'New page',
              onPressed: onAdd,
            ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            icon: const Icon(Icons.unfold_less, color: EverforestColors.grey, size: 16),
            tooltip: 'Collapse all pages',
            onPressed: onCollapseAll,
          ),
        ],
      ),
    );
  }
}

class ZenNewPageButton extends StatelessWidget {
  const ZenNewPageButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF242B2E),
      child: InkWell(
        onTap: onPressed,
        child: const SizedBox(
          height: 36,
          child: Row(
            children: [
              SizedBox(width: 12),
              Icon(Icons.add, color: EverforestColors.green, size: 18),
              SizedBox(width: 8),
              Text(
                'New page',
                style: TextStyle(color: EverforestColors.fg, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MoreIconButton extends StatelessWidget {
  const MoreIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        icon: Icon(icon, size: 16, color: EverforestColors.grey),
        onPressed: onPressed,
      ),
    );
  }
}
