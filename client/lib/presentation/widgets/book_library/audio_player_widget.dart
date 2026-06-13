import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class AudioPlayerWidget extends StatelessWidget {
  const AudioPlayerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: EverforestColors.bg2, width: 1),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: EverforestColors.bg2,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Icon(Icons.headset, color: EverforestColors.fg, size: 64),
          const SizedBox(height: 16),
          Text(
            'Sample Audiobook',
            style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            'Author Name',
            style: TextStyle(color: EverforestColors.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: EverforestColors.green,
              inactiveTrackColor: EverforestColors.bg2,
              thumbColor: EverforestColors.green,
            ),
            child: Slider(
              value: 0.3,
              onChanged: (val) {},
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('01:23:45', style: TextStyle(color: EverforestColors.grey, fontSize: 12)),
              Text('-03:45:12', style: TextStyle(color: EverforestColors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(Icons.replay_10, color: EverforestColors.fg, size: 32),
                onPressed: () {},
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EverforestColors.green.withOpacity(0.2),
                ),
                padding: const EdgeInsets.all(16),
                child: Icon(Icons.play_arrow, color: EverforestColors.green, size: 48),
              ),
              IconButton(
                icon: Icon(Icons.forward_10, color: EverforestColors.fg, size: 32),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
