import os

# 1. selection_menu_service.dart
p1 = 'client/lib/appflowy/src/editor/selection_menu/selection_menu_service.dart'
with open(p1, 'r', encoding='utf-8') as f:
    t1 = f.read()
t1 = t1.replace(
    '  Widget _buildChildren() {\n    final items = _searchItems(_keyword);',
    '  Widget _buildChildren() {\n    final items = _children ?? _searchItems(_keyword);'
)
with open(p1, 'w', encoding='utf-8') as f:
    f.write(t1)
print('Fixed selection_menu_service.dart')

# 2. item_positions_listener.dart
p2 = 'client/lib/appflowy/src/flutter/scrollable_positioned_list/src/item_positions_listener.dart'
with open(p2, 'r', encoding='utf-8') as f:
    t2 = f.read()
t2 = t2.replace("import 'scrollable_positioned_list.dart';\n", "")
t2 = t2.replace("bool operator ==(dynamic other)", "bool operator ==(Object other)")
with open(p2, 'w', encoding='utf-8') as f:
    f.write(t2)
print('Fixed item_positions_listener.dart')

# 3. positioned_list.dart
p3 = 'client/lib/appflowy/src/flutter/scrollable_positioned_list/src/positioned_list.dart'
with open(p3, 'r', encoding='utf-8') as f:
    t3 = f.read()
old_doc = '''  /// {@template flutter.widgets.scroll_view.shrinkWrap}
  /// Whether the extent of the scroll view in the [scrollDirection] should be
  /// determined by the contents being viewed.
  ///
  ///  Defaults to false.
  ///
  /// See [ScrollView.shrinkWrap].
  final bool shrinkWrap;'''

new_doc = '''  /// {@template flutter.widgets.scroll_view.shrinkWrap}
  /// Whether the extent of the scroll view in the [scrollDirection] should be
  /// determined by the contents being viewed.
  ///
  ///  Defaults to false.
  ///
  /// See [ScrollView.shrinkWrap].
  /// {@endtemplate}
  final bool shrinkWrap;'''
t3 = t3.replace(old_doc, new_doc)
with open(p3, 'w', encoding='utf-8') as f:
    f.write(t3)
print('Fixed positioned_list.dart')

# 4. zen_workspace.dart
p4 = 'client/lib/presentation/widgets/zen_workspace.dart'
with open(p4, 'r', encoding='utf-8') as f:
    t4 = f.read()
t4 = t4.replace("import 'package:appflowy_editor/src/editor/editor_component/service/shortcuts/command/copy_paste_extension.dart';\n", "")
t4 = t4.replace("import '../../api_client.dart';\n", "")
with open(p4, 'w', encoding='utf-8') as f:
    f.write(t4)
print('Fixed zen_workspace.dart')
