import 'dart:ui';
import 'package:flutter/material.dart';

class InputCurtain extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;
  const InputCurtain({super.key, required this.isOpen, required this.onClose});

  @override Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic,
      top: isOpen ? 0 : -300, left: 0, right: 0, height: 200,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: const BoxDecoration(color: Color(0x05FFFFFF), border: Border(bottom: BorderSide(color: Color(0xFF27272A)))),
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 24, left: 16, right: 16, bottom: 12),
            child: Column(
              children: [
                Expanded(child: Row(children: [
                  Expanded(child: TextField(autofocus: true, style: const TextStyle(color: Colors.white, fontSize: 18), decoration: const InputDecoration(border: InputBorder.none, hintText: 'Fast capture...', hintStyle: TextStyle(color: Colors.white30)))),
                  const _MicPulse(),
                ])),
                GestureDetector(onTap: onClose, child: const Icon(Icons.keyboard_arrow_up, color: Colors.white54)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MicPulse extends StatefulWidget { const _MicPulse(); @override State<_MicPulse> createState() => _MState(); }
class _MState extends State<_MicPulse> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  @override void dispose() { c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: c, builder: (_,__) => Container(
    decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0x6600E5FF).withOpacity(1-c.value), spreadRadius: c.value*15, blurRadius: 10)]),
    child: IconButton(icon: const Icon(Icons.mic, color: Color(0xFF00E5FF)), onPressed: (){}),
  ));
}
