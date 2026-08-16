import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../theme/everforest_colors.dart';

/// Live watch-session chip: counts down to the next 30-min points block
/// (-10 PTS each). Shown while a YouTube session is active.
class ActiveSessionTimerOverlay extends StatefulWidget {
  final DateTime startedAt;
  final int estCost;

  const ActiveSessionTimerOverlay({
    super.key,
    required this.startedAt,
    required this.estCost,
  });

  @override
  State<ActiveSessionTimerOverlay> createState() => _ActiveSessionTimerOverlayState();
}

class _ActiveSessionTimerOverlayState extends State<ActiveSessionTimerOverlay> {
  static const _blockMin = 30;
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _nextBlockIn();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _remaining = _nextBlockIn());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration _nextBlockIn() {
    final elapsed = DateTime.now().difference(widget.startedAt);
    final intoBlock = elapsed.inSeconds % (_blockMin * 60);
    return Duration(seconds: _blockMin * 60 - intoBlock);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: EverforestColors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: EverforestColors.red.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer, color: EverforestColors.red, size: 16),
          const SizedBox(width: 8),
          Text('${_fmt(_remaining)} until -${widget.estCost} PTS',
              style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: EverforestColors.red, borderRadius: BorderRadius.circular(4)),
            child: const Text('-10 PTS',
                style: TextStyle(color: EverforestColors.bg0, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}