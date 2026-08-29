import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import '../../../../core/obsidian/zen_collab_service.dart';

/// Renders remote collaborators' cursors as an overlay on top of the editor.
/// Repaints on presence updates, document changes and scroll.
class RemoteCursorOverlay extends StatefulWidget {
  const RemoteCursorOverlay({
    super.key,
    required this.editorState,
    required this.scrollController,
    required this.presences,
  });

  final EditorState editorState;
  final EditorScrollController scrollController;
  final ValueListenable<Map<String, RemotePresence>> presences;

  @override
  State<RemoteCursorOverlay> createState() => _RemoteCursorOverlayState();
}

class _RemoteCursorOverlayState extends State<RemoteCursorOverlay> {
  @override
  void initState() {
    super.initState();
    widget.presences.addListener(_repaint);
    widget.editorState.document.root.addListener(_repaint);
    widget.scrollController.offsetNotifier.addListener(_repaint);
  }

  @override
  void dispose() {
    widget.presences.removeListener(_repaint);
    widget.editorState.document.root.removeListener(_repaint);
    widget.scrollController.offsetNotifier.removeListener(_repaint);
    super.dispose();
  }

  void _repaint() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final widgets = <Widget>[];
    widget.presences.value.forEach((id, p) {
      if (now.difference(p.lastSeen) > const Duration(seconds: 10)) return;
      final path = p.blockPath;
      if (path == null) return;
      final node = widget.editorState.getNodeAtPath(path);
      final selectable = node?.selectable;
      if (selectable == null) return;
      final position = Position(path: path, offset: p.selectionOffset);
      final local = selectable.getCursorRectInPosition(position);
      final rect = local == null
          ? null
          : selectable.transformRectToGlobal(local);
      if (rect == null) return;
      final topLeft = box.globalToLocal(rect.topLeft);
      widgets.add(Positioned(
        left: topLeft.dx,
        top: topLeft.dy,
        child: IgnorePointer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 2,
                height: rect.height,
                color: Color(int.parse('FF${p.colorHex.replaceFirst('#', '')}', radix: 16)),
              ),
              Container(
                margin: const EdgeInsets.only(top: 1),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Color(int.parse('FF${p.colorHex.replaceFirst('#', '')}', radix: 16)),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  p.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ));
    });

    return Stack(
      clipBehavior: Clip.none,
      children: widgets,
    );
  }
}
