import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'zen_embed_models.dart';

/// The inline render window: header bar + compact preview body.
class ZenEmbedCard extends StatefulWidget {
  const ZenEmbedCard({
    super.key,
    required this.spec,
    this.ref,
    required this.height,
    required this.onHeightChanged,
    required this.onMove,
  });

  final ZenEmbedSpec spec;
  final String? ref;
  final double height;
  final ValueChanged<double> onHeightChanged;
  final ValueChanged<int> onMove;

  @override
  State<ZenEmbedCard> createState() => _ZenEmbedCardState();
}

class _ZenEmbedCardState extends State<ZenEmbedCard> {
  double _dragHeight = 0;

  @override
  Widget build(BuildContext context) {
    final height = _dragHeight > 0 ? _dragHeight : widget.height;
    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: EverforestColors.bg2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(context),
          SizedBox(
            height: height,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openFull(context),
              child: RepaintBoundary(
                child: ClipRect(child: widget.spec.preview(widget.ref)),
              ),
            ),
          ),
          _resizeHandle(),
        ],
      ),
    );
  }

  Widget _resizeHandle() {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpDown,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (details) {
          _dragHeight = widget.height;
        },
        onVerticalDragUpdate: (details) {
          setState(() {
            _dragHeight = (_dragHeight + details.delta.dy)
                .clamp(ZenEmbedKeys.minHeight, ZenEmbedKeys.maxHeight);
          });
        },
        onVerticalDragEnd: (details) {
          widget.onHeightChanged(_dragHeight.roundToDouble());
          setState(() => _dragHeight = 0);
        },
        child: Container(
          height: 18,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: EverforestColors.bg2)),
          ),
          child: const Icon(
            Icons.drag_handle,
            size: 14,
            color: EverforestColors.grey,
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      height: 34,
      color: const Color(0xFF1E2326),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(widget.spec.icon, size: 15, color: EverforestColors.green),
          const SizedBox(width: 8),
          Text(
            widget.spec.label,
            style: const TextStyle(
              color: EverforestColors.fg,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 16,
            tooltip: 'Move embed up',
            icon: const Icon(
              Icons.keyboard_arrow_up,
              color: EverforestColors.grey,
            ),
            onPressed: () => widget.onMove(-1),
          ),
          const SizedBox(width: 4),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 16,
            tooltip: 'Move embed down',
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: EverforestColors.grey,
            ),
            onPressed: () => widget.onMove(1),
          ),
          const SizedBox(width: 4),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 16,
            tooltip: 'Open ${widget.spec.label} full screen',
            icon: const Icon(Icons.open_in_full, color: EverforestColors.grey),
            onPressed: () => _openFull(context),
          ),
        ],
      ),
    );
  }

  void _openFull(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => widget.spec.full()),
    );
  }
}
