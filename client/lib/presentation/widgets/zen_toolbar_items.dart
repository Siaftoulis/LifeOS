import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import '../../appflowy/src/editor/block_component/callout_block_component/callout_block_component.dart';
import '../../appflowy/src/editor/block_component/toggle_block_component/toggle_block_component.dart';

// Items mirroring the Uflow floating toolbar menu, minus its AI buttons.
// Comment / Font / Equation have no engine support in AppFlowy 1.5.2,
// so they render as disabled placeholders (ponytail: engine gap, not styling).

ToolbarItem formatItemById(String id) =>
    markdownFormatItems.firstWhere((item) => item.id == id);

final ToolbarItem zenCommentItem = _disabledItem(
  id: 'zen.comment',
  icon: Icons.chat_bubble_outline,
  tooltip: 'Comment (δεν υποστηρίζεται ακόμα)',
);

final ToolbarItem zenFontItem = _disabledItem(
  id: 'zen.font',
  icon: Icons.font_download_outlined,
  tooltip: 'Font (δεν υποστηρίζεται ακόμα)',
);

final ToolbarItem zenEquationItem = _disabledItem(
  id: 'zen.equation',
  icon: Icons.functions,
  tooltip: 'Equation (δεν υποστηρίζεται ακόμα)',
);

final ToolbarItem zenTodoListItem = _formatNodeItem(
  id: 'zen.todo_list',
  icon: Icons.check_box_outline_blank,
  targetType: TodoListBlockKeys.type,
  tooltip: 'Checkbox list',
);

final ToolbarItem zenToggleItem = _formatNodeItem(
  id: 'zen.toggle',
  icon: Icons.unfold_more,
  targetType: ToggleBlockKeys.type,
  tooltip: 'Toggle list',
);

final ToolbarItem zenCalloutItem = _formatNodeItem(
  id: 'zen.callout',
  icon: Icons.info_outline,
  targetType: CalloutBlockKeys.type,
  tooltip: 'Callout',
);

ToolbarItem _formatNodeItem({
  required String id,
  required IconData icon,
  required String targetType,
  required String tooltip,
}) {
  return ToolbarItem(
    id: id,
    group: 3,
    isActive: onlyShowInSingleSelectionAndTextType,
    builder: (context, editorState, highlightColor, iconColor) {
      final selection = editorState.selection!;
      final node = editorState.getNodeAtPath(selection.start.path)!;
      final isHighlight = node.type == targetType;
      return SVGIconItemWidget(
        iconBuilder: (context) => Icon(
          icon,
          size: 18,
          color: isHighlight ? highlightColor : iconColor,
        ),
        isHighlight: isHighlight,
        highlightColor: highlightColor,
        iconColor: iconColor,
        tooltip: tooltip,
        onPressed: () => editorState.formatNode(
          selection,
          (node) => node.copyWith(
            type: isHighlight ? ParagraphBlockKeys.type : targetType,
          ),
        ),
      );
    },
  );
}

ToolbarItem _disabledItem({
  required String id,
  required IconData icon,
  required String tooltip,
}) {
  return ToolbarItem(
    id: id,
    group: 5,
    isActive: onlyShowInTextType,
    builder: (context, editorState, highlightColor, iconColor) {
      return SVGIconItemWidget(
        iconBuilder: (context) => Opacity(
          opacity: 0.35,
          child: Icon(icon, size: 18, color: iconColor),
        ),
        isHighlight: false,
        highlightColor: highlightColor,
        iconColor: iconColor,
        tooltip: tooltip,
      );
    },
  );
}
