import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/obsidian/vault_scanner.dart';
import '../../theme/everforest_colors.dart';

class GraphNodeData {
  final String path;
  final String name;
  Offset position;
  Offset velocity;
  bool isDragged;

  GraphNodeData({
    required this.path,
    required this.name,
    required this.position,
    this.velocity = Offset.zero,
    this.isDragged = false,
  });
}

class ZenGraphView extends StatefulWidget {
  final VaultScanner scanner;
  final String? selectedPath;
  final ValueChanged<String> onNodeSelected;

  const ZenGraphView({
    super.key,
    required this.scanner,
    this.selectedPath,
    required this.onNodeSelected,
  });

  @override
  State<ZenGraphView> createState() => _ZenGraphViewState();
}

class _ZenGraphViewState extends State<ZenGraphView> with SingleTickerProviderStateMixin {
  late AnimationController _physicsController;
  final Map<String, GraphNodeData> _graphNodes = {};
  final TransformationController _transformController = TransformationController();

  Size _canvasSize = const Size(1000, 800);
  String? _draggedNodeKey;

  @override
  void initState() {
    super.initState();
    _physicsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _physicsController.addListener(_stepPhysicsSimulation);
    widget.scanner.addListener(_rebuildGraphNodes);
    _rebuildGraphNodes();
  }

  @override
  void dispose() {
    _physicsController.dispose();
    widget.scanner.removeListener(_rebuildGraphNodes);
    _transformController.dispose();
    super.dispose();
  }

  void _rebuildGraphNodes() {
    final rand = Random(42);
    final center = Offset(_canvasSize.width / 2, _canvasSize.height / 2);

    final currentKeys = Set<String>.from(widget.scanner.nodes.keys);
    _graphNodes.removeWhere((key, _) => !currentKeys.contains(key));

    int count = widget.scanner.nodes.length;
    double radius = max(200.0, count * 35.0);

    int index = 0;
    for (final entry in widget.scanner.nodes.entries) {
      if (!_graphNodes.containsKey(entry.key)) {
        double angle = (index / max(1, count)) * 2 * pi;
        double r = radius * (0.6 + rand.nextDouble() * 0.4);
        Offset initialPos = center + Offset(cos(angle) * r, sin(angle) * r);

        _graphNodes[entry.key] = GraphNodeData(
          path: entry.key,
          name: entry.value.name.replaceAll('.md', ''),
          position: initialPos,
        );
      }
      index++;
    }

    if (mounted) setState(() {});
  }

  void _stepPhysicsSimulation() {
    if (_graphNodes.isEmpty) return;

    const double repulsionStrength = 18000.0;
    const double springStrength = 0.04;
    const double gravityStrength = 0.008;
    const double damping = 0.82;
    final center = Offset(_canvasSize.width / 2, _canvasSize.height / 2);

    final nodeList = _graphNodes.values.toList();

    // 1. Repulsion forces between nodes
    for (int i = 0; i < nodeList.length; i++) {
      for (int j = i + 1; j < nodeList.length; j++) {
        final nodeA = nodeList[i];
        final nodeB = nodeList[j];
        final delta = nodeA.position - nodeB.position;
        double distSq = delta.dx * delta.dx + delta.dy * delta.dy;
        if (distSq < 400) distSq = 400;
        double dist = sqrt(distSq);

        final force = (delta / dist) * (repulsionStrength / distSq);
        if (!nodeA.isDragged) nodeA.velocity += force;
        if (!nodeB.isDragged) nodeB.velocity -= force;
      }
    }

    // 2. Spring attraction along links
    widget.scanner.graph.links.forEach((source, targets) {
      final sourceNode = _graphNodes[source];
      if (sourceNode == null) return;

      for (final target in targets) {
        final targetNode = _graphNodes[target];
        if (targetNode == null) continue;

        final delta = targetNode.position - sourceNode.position;
        final force = delta * springStrength;
        if (!sourceNode.isDragged) sourceNode.velocity += force;
        if (!targetNode.isDragged) targetNode.velocity -= force;
      }
    });

    // 3. Central gravity & velocity integration
    for (final node in nodeList) {
      if (node.isDragged) continue;
      final gravity = (center - node.position) * gravityStrength;
      node.velocity = (node.velocity + gravity) * damping;
      node.position += node.velocity;
    }

    setState(() {});
  }

  Offset _getCanvasCoordinates(Offset globalPos, RenderBox box) {
    final Offset localPos = box.globalToLocal(globalPos);
    final Matrix4 transform = _transformController.value;
    final Matrix4 inverse = Matrix4.inverted(transform);
    return MatrixUtils.transformPoint(inverse, localPos);
  }

  void _handlePanStart(DragStartDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset canvasPos = _getCanvasCoordinates(details.globalPosition, box);

    String? closestPath;
    double minDistance = 40.0; // Click radius

    for (final node in _graphNodes.values) {
      double dist = (node.position - canvasPos).distance;
      if (dist < minDistance) {
        minDistance = dist;
        closestPath = node.path;
      }
    }

    if (closestPath != null) {
      _draggedNodeKey = closestPath;
      _graphNodes[closestPath]!.isDragged = true;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_draggedNodeKey != null) {
      final RenderBox box = context.findRenderObject() as RenderBox;
      final Offset canvasPos = _getCanvasCoordinates(details.globalPosition, box);
      setState(() {
        _graphNodes[_draggedNodeKey!]!.position = canvasPos;
      });
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_draggedNodeKey != null) {
      _graphNodes[_draggedNodeKey!]!.isDragged = false;
      _draggedNodeKey = null;
    }
  }

  void _handleTap(TapUpDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset canvasPos = _getCanvasCoordinates(details.globalPosition, box);

    String? closestPath;
    double minDistance = 40.0; // Touch radius for mobile & desktop

    for (final node in _graphNodes.values) {
      double dist = (node.position - canvasPos).distance;
      if (dist < minDistance) {
        minDistance = dist;
        closestPath = node.path;
      }
    }

    if (closestPath != null) {
      widget.onNodeSelected(closestPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final newWidth = max(constraints.maxWidth, 600.0);
        final newHeight = max(constraints.maxHeight, 500.0);

        if (_canvasSize.width != newWidth || _canvasSize.height != newHeight) {
          _canvasSize = Size(newWidth, newHeight);
          _rebuildGraphNodes();
        }

        return Container(
          color: EverforestColors.bg0,
          child: Stack(
            children: [
              GestureDetector(
                onTapUp: _handleTap,
                onPanStart: _handlePanStart,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: _handlePanEnd,
                child: InteractiveViewer(
                  transformationController: _transformController,
                  boundaryMargin: const EdgeInsets.all(2000),
                  minScale: 0.1,
                  maxScale: 5.0,
                  child: CustomPaint(
                    size: _canvasSize,
                    painter: GraphPainter(
                      nodes: _graphNodes,
                      links: widget.scanner.graph.links,
                      selectedPath: widget.selectedPath,
                      canvasSize: _canvasSize,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: EverforestColors.bg1.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: EverforestColors.bg2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hub, color: EverforestColors.green, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Graph View (${_graphNodes.length} Nodes)',
                        style: const TextStyle(
                          color: EverforestColors.fg,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class GraphPainter extends CustomPainter {
  final Map<String, GraphNodeData> nodes;
  final Map<String, List<String>> links;
  final String? selectedPath;
  final Size canvasSize;

  GraphPainter({
    required this.nodes,
    required this.links,
    this.selectedPath,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..color = EverforestColors.grey.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final selectedEdgePaint = Paint()
      ..color = EverforestColors.green.withValues(alpha: 0.85)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Draw Edges
    links.forEach((source, targets) {
      final sourceNode = nodes[source];
      if (sourceNode == null) return;

      for (final target in targets) {
        final targetNode = nodes[target];
        if (targetNode == null) continue;

        final isSelected = source == selectedPath || target == selectedPath;
        canvas.drawLine(
          sourceNode.position,
          targetNode.position,
          isSelected ? selectedEdgePaint : edgePaint,
        );
      }
    });

    // Draw Nodes & Labels
    final defaultNodePaint = Paint()..color = const Color(0xFFD699B6);
    final selectedNodePaint = Paint()..color = EverforestColors.green;
    final glowPaint = Paint()
      ..color = EverforestColors.green.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    nodes.forEach((path, node) {
      final isSelected = path == selectedPath;
      final radius = isSelected ? 10.0 : 7.0;

      if (isSelected) {
        canvas.drawCircle(node.position, radius + 6, glowPaint);
        canvas.drawCircle(node.position, radius, selectedNodePaint);
      } else {
        canvas.drawCircle(node.position, radius, defaultNodePaint);
      }

      // Label background pill for ultra readability on Mobile & PC
      final textSpan = TextSpan(
        text: node.name,
        style: TextStyle(
          color: isSelected ? EverforestColors.green : EverforestColors.fg,
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final labelOffset = node.position + Offset(-textPainter.width / 2, radius + 6);
      final labelBgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          labelOffset.dx - 4,
          labelOffset.dy - 2,
          textPainter.width + 8,
          textPainter.height + 4,
        ),
        const Radius.circular(4),
      );

      canvas.drawRRect(
        labelBgRect,
        Paint()..color = EverforestColors.bg1.withValues(alpha: 0.85),
      );

      textPainter.paint(canvas, labelOffset);
    });
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) => true;
}
