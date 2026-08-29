import 'package:flutter/material.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import '../../../theme/everforest_colors.dart';

class ZenEmbedKeys {
  const ZenEmbedKeys._();

  static const String type = 'zen_embed';
  static const String module = 'module';
  static const String ref = 'ref';
  static const String height = 'height';

  static const double minHeight = 120;
  static const double maxHeight = 640;
  static const double defaultHeight = 200;
}

double zenEmbedHeightOf(Node node) {
  final h = node.attributes[ZenEmbedKeys.height];
  return h is num ? h.toDouble() : ZenEmbedKeys.defaultHeight;
}

Node zenEmbedNode({required String module, String? ref, double? height}) {
  return Node(
    type: ZenEmbedKeys.type,
    attributes: {
      ZenEmbedKeys.module: module,
      if (ref != null) ZenEmbedKeys.ref: ref,
      if (height != null) ZenEmbedKeys.height: height,
    },
  );
}

/// Moves a zen_embed block one step up (-1) or down (+1) among its siblings.
Future<void> moveZenEmbedBlock(
  EditorState editorState,
  Node node,
  int direction,
) async {
  final siblings = node.parent?.children;
  if (siblings == null) return;
  final index = siblings.indexOf(node);
  final target = index + direction;
  if (index < 0 || target < 0 || target >= siblings.length) return;

  final targetPath = direction < 0
      ? siblings[target].path
      : siblings[target].path.next;
  final transaction = editorState.transaction
    ..insertNode(targetPath, node, deepCopy: true)
    ..deleteNode(node);
  await editorState.apply(transaction);
}

class ZenEmbedSpec {
  const ZenEmbedSpec({
    required this.id,
    required this.label,
    required this.icon,
    required this.preview,
    required this.full,
  });

  final String id;
  final String label;
  final IconData icon;

  /// Compact inline preview rendered inside the note. [ref] is an optional
  /// entity reference (e.g. a movie id) for single-entity embeds.
  final Widget Function(String? ref) preview;

  /// The full module opened on a separate page.
  final Widget Function() full;
}

class EmbedCardData {
  const EmbedCardData(this.title, this.subtitle, this.color);

  final String title;
  final String subtitle;
  final Color color;
}

class CardStrip extends StatelessWidget {
  const CardStrip({super.key, required this.items});

  final List<EmbedCardData> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Nothing here yet — tap to open the library',
          style: TextStyle(color: EverforestColors.grey),
        ),
      );
    }
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final it = items[index];
        return Container(
          width: 110,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: it.color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                it.title,
                style: const TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                it.subtitle,
                style: const TextStyle(
                  color: EverforestColors.grey,
                  fontSize: 10.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
