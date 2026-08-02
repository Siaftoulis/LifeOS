import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

class CodeBlockKeys {
  const CodeBlockKeys._();
  static const String type = 'code_block';
  static const String delta = 'delta';
  static const String language = 'language';
}

Node codeBlockNode({
  Delta? delta,
  String language = 'dart',
}) {
  return Node(
    type: CodeBlockKeys.type,
    attributes: {
      CodeBlockKeys.delta: (delta ?? Delta()).toJson(),
      CodeBlockKeys.language: language,
    },
  );
}

class CodeBlockComponentBuilder extends BlockComponentBuilder {
  CodeBlockComponentBuilder({super.configuration});

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return CodeBlockComponentWidget(
      key: node.key,
      node: node,
    );
  }
}

class CodeBlockComponentWidget extends StatefulWidget implements BlockComponentWidget {
  const CodeBlockComponentWidget({
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
  State<CodeBlockComponentWidget> createState() => _CodeBlockComponentWidgetState();
}

class _CodeBlockComponentWidgetState extends State<CodeBlockComponentWidget>
    with BlockComponentConfigurable, SelectableMixin, DefaultSelectableMixin {
  @override
  final forwardKey = GlobalKey(debugLabel: 'code_block_rich_text');

  @override
  GlobalKey<State<StatefulWidget>> get containerKey => widget.node.key;

  @override
  GlobalKey<State<StatefulWidget>> blockComponentKey = GlobalKey(debugLabel: 'code_block');

  @override
  Node get node => widget.node;

  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  bool _isCopied = false;

  @override
  Widget build(BuildContext context) {
    final attributes = widget.node.attributes;
    final language = attributes[CodeBlockKeys.language] as String? ?? 'dart';
    final editorState = context.read<EditorState>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E2326),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: const Color(0xFF343F44),
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              color: const Color(0xFF272E33),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    language.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFA7C080),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      final text = widget.node.delta?.toPlainText() ?? '';
                      Clipboard.setData(ClipboardData(text: text));
                      setState(() => _isCopied = true);
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) setState(() => _isCopied = false);
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          _isCopied ? Icons.check : Icons.copy,
                          size: 14,
                          color: _isCopied ? const Color(0xFFA7C080) : Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isCopied ? 'Copied' : 'Copy',
                          style: TextStyle(
                            color: _isCopied ? const Color(0xFFA7C080) : Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: AppFlowyRichText(
                key: forwardKey,
                node: widget.node,
                editorState: editorState,
                delegate: this,
                placeholderText: 'Write code here...',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
