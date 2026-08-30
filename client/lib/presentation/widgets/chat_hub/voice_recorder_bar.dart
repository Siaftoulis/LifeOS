import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class VoiceRecorderBar extends StatefulWidget {
  final VoidCallback onCancel;
  final Function(Duration duration) onSend;

  const VoiceRecorderBar({
    super.key,
    required this.onCancel,
    required this.onSend,
  });

  @override
  State<VoiceRecorderBar> createState() => _VoiceRecorderBarState();
}

class _VoiceRecorderBarState extends State<VoiceRecorderBar> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _timer;
  int _secondsElapsed = 0;
  final List<double> _liveAmplitudes = List.generate(20, (_) => 0.2);
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) return;
      setState(() {
        if (t.tick % 10 == 0) {
          _secondsElapsed++;
        }
        // Shift live amplitudes to create animated audio waveform
        _liveAmplitudes.removeAt(0);
        _liveAmplitudes.add((_rnd.nextDouble() * 0.8) + 0.2);
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _formatTimer() {
    final m = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EverforestColors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          // Pulsing Recording Indicator
          FadeTransition(
            opacity: _animController,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: EverforestColors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Timer
          Text(
            _formatTimer(),
            style: const TextStyle(
              color: EverforestColors.fg,
              fontSize: 14,
              fontFamily: 'JetBrainsMono',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 14),
          // Live Animated Waveform Bars
          Expanded(
            child: SizedBox(
              height: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _liveAmplitudes.map((amp) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: 3,
                    height: 24 * amp,
                    decoration: BoxDecoration(
                      color: EverforestColors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Cancel Button
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: EverforestColors.grey, size: 22),
            tooltip: 'Cancel Recording',
            onPressed: widget.onCancel,
          ),
          const SizedBox(width: 4),
          // Send Button
          Container(
            decoration: const BoxDecoration(
              color: EverforestColors.green,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: EverforestColors.bg0, size: 20),
              tooltip: 'Send Voice Message',
              onPressed: () {
                final dur = Duration(seconds: max(1, _secondsElapsed));
                widget.onSend(dur);
              },
            ),
          ),
        ],
      ),
    );
  }
}
