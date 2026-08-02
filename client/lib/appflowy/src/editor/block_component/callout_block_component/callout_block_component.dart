import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

class CalloutBlockKeys {
  const CalloutBlockKeys._();
  static const String type = 'callout';
  static const String delta = 'delta';
  static const String icon = 'icon';
  static const String backgroundColor = 'bg_color';
}

Node calloutNode({
  Delta? delta,
  String icon = '📌',
  String backgroundColor = '#263238',
}) {
  return Node(
    type: CalloutBlockKeys.type,
    attributes: {
      CalloutBlockKeys.delta: (delta ?? Delta()).toJson(),
      CalloutBlockKeys.icon: icon,
      CalloutBlockKeys.backgroundColor: backgroundColor,
    },
  );
}

class CalloutBlockComponentBuilder extends BlockComponentBuilder {
  CalloutBlockComponentBuilder({super.configuration});

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return CalloutBlockComponentWidget(
      key: node.key,
      node: node,
    );
  }
}

class CalloutBlockComponentWidget extends StatefulWidget implements BlockComponentWidget {
  const CalloutBlockComponentWidget({
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
  State<CalloutBlockComponentWidget> createState() => _CalloutBlockComponentWidgetState();
}

class _CalloutBlockComponentWidgetState extends State<CalloutBlockComponentWidget>
    with BlockComponentConfigurable, SelectableMixin, DefaultSelectableMixin {
  @override
  final forwardKey = GlobalKey(debugLabel: 'callout_rich_text');

  @override
  GlobalKey<State<StatefulWidget>> get containerKey => widget.node.key;

  @override
  GlobalKey<State<StatefulWidget>> blockComponentKey = GlobalKey(debugLabel: 'callout_block');

  @override
  Node get node => widget.node;

  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Widget build(BuildContext context) {
    final attributes = widget.node.attributes;
    final icon = attributes[CalloutBlockKeys.icon] as String? ?? '📌';
    final bgColorHex = attributes[CalloutBlockKeys.backgroundColor] as String? ?? '#263238';

    Color bgColor;
    try {
      bgColor = Color(int.parse(bgColorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      bgColor = const Color(0xFF263238);
    }

    final editorState = context.read<EditorState>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: bgColor.withValues(alpha: 0.8),
            width: 1.0,
          ),
        ),
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppFlowyRichText(
                key: forwardKey,
                node: widget.node,
                editorState: editorState,
                delegate: this,
                placeholderText: 'Type callout text...',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
