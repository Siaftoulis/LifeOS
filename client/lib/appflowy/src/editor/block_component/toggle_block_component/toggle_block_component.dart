import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

class ToggleBlockKeys {
  const ToggleBlockKeys._();
  static const String type = 'toggle_list';
  static const String delta = 'delta';
  static const String collapsed = 'collapsed';
}

Node toggleListNode({
  Delta? delta,
  bool collapsed = false,
  List<Node>? children,
}) {
  return Node(
    type: ToggleBlockKeys.type,
    attributes: {
      ToggleBlockKeys.delta: (delta ?? Delta()).toJson(),
      ToggleBlockKeys.collapsed: collapsed,
    },
    children: children ?? [],
  );
}

class ToggleBlockComponentBuilder extends BlockComponentBuilder {
  ToggleBlockComponentBuilder({super.configuration});

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return ToggleBlockComponentWidget(
      key: node.key,
      node: node,
    );
  }
}

class ToggleBlockComponentWidget extends StatefulWidget implements BlockComponentWidget {
  const ToggleBlockComponentWidget({
    super.key,
    required this.node,
    this.showActions = false,
    this.actionBuilder,
    this.configuration = const BlockComponentConfiguration(),
  });

  @override
  final Node node;
  @override
  final bool showActions;
  @override
  final BlockComponentActionBuilder? actionBuilder;
  @override
  final BlockComponentConfiguration configuration;

  @override
  State<ToggleBlockComponentWidget> createState() => _ToggleBlockComponentWidgetState();
}

class _ToggleBlockComponentWidgetState extends State<ToggleBlockComponentWidget>
    with BlockComponentConfigurable, SelectableMixin, DefaultSelectableMixin {
  @override
  final forwardKey = GlobalKey(debugLabel: 'toggle_rich_text');

  @override
  GlobalKey<State<StatefulWidget>> get containerKey => widget.node.key;

  @override
  GlobalKey<State<StatefulWidget>> blockComponentKey = GlobalKey(debugLabel: 'toggle_block');

  @override
  Node get node => widget.node;

  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Widget build(BuildContext context) {
    final isCollapsed = widget.node.attributes[ToggleBlockKeys.collapsed] as bool? ?? false;
    final editorState = context.read<EditorState>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () async {
                  final transaction = editorState.transaction;
                  transaction.updateNode(
                    widget.node,
                    {ToggleBlockKeys.collapsed: !isCollapsed},
                  );
                  await editorState.apply(transaction);
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0, right: 6.0),
                  child: Icon(
                    isCollapsed ? Icons.arrow_right : Icons.arrow_drop_down,
                    size: 20,
                    color: const Color(0xFFA7C080),
                  ),
                ),
              ),
              Expanded(
                child: AppFlowyRichText(
                  key: forwardKey,
                  node: widget.node,
                  editorState: editorState,
                  delegate: this,
                  placeholderText: 'Toggle list...',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
