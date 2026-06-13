import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class MovieReviewEditor extends StatelessWidget {
  const MovieReviewEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg1,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Write a Review', style: TextStyle(color: EverforestColors.fg, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => const Icon(Icons.star, color: EverforestColors.yellow, size: 40)),
          ),
          const SizedBox(height: 24),
          TextField(
            maxLines: 4,
            style: const TextStyle(color: EverforestColors.fg),
            decoration: InputDecoration(
              hintText: 'What did you think about this movie?',
              hintStyle: const TextStyle(color: EverforestColors.grey),
              filled: true,
              fillColor: EverforestColors.bg0,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: EverforestColors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Save Review (+5 Points)', style: TextStyle(color: EverforestColors.bg0, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
