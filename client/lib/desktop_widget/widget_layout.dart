import 'dart:ui';
import 'package:flutter/material.dart';
import 'habit_panel.dart';
import 'vm_panel.dart';

class WidgetGlassmorphismLayout extends StatelessWidget {
  final Map<String, dynamic> data;
  const WidgetGlassmorphismLayout({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.black.withOpacity(0.2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: HabitPanel(data: data)),
              const SizedBox(width: 16),
              Expanded(child: VmPanel(data: data)),
            ],
          ),
        ),
      ),
    );
  }
}
