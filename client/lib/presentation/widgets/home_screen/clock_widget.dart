import 'package:flutter/material.dart';
import 'dart:async';
import '../../../theme/everforest_colors.dart';

class ClockWidget extends StatefulWidget {
  const ClockWidget({super.key});

  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';
    final dateStr = '${_now.day}/${_now.month}/${_now.year}';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(timeStr, style: const TextStyle(color: EverforestColors.fg, fontSize: 64, fontWeight: FontWeight.bold, letterSpacing: 4)),
        Text(dateStr, style: const TextStyle(color: EverforestColors.grey, fontSize: 18, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
