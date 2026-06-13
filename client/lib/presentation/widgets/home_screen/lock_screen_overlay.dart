import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'clock_widget.dart';
import 'notifications_feed.dart';

class LockScreenOverlay extends StatefulWidget {
  const LockScreenOverlay({super.key});

  @override
  State<LockScreenOverlay> createState() => _LockScreenOverlayState();
}

class _LockScreenOverlayState extends State<LockScreenOverlay> {
  String _pin = '';

  void _onDigit(String digit) {
    setState(() {
      if (_pin.length < 4) _pin += digit;
    });
    if (_pin.length == 4) {
      // Validate PIN stub
      if (_pin == '1234') {
        // Unlock logic
      } else {
        setState(() => _pin = '');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      child: Stack(
        children: [
          const Positioned(top: 40, left: 16, right: 16, child: ClockWidget()),
          const Positioned(top: 140, left: 16, right: 16, bottom: 400, child: NotificationsFeed()),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _pin.length ? EverforestColors.green : EverforestColors.bg2,
                    ),
                  )),
                ),
                const SizedBox(height: 24),
                _buildKeypad(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          for (var i = 1; i <= 9; i++) _keyBtn('$i'),
          const SizedBox(), _keyBtn('0'), _keyBtn('C', () => setState(() => _pin = '')),
        ],
      ),
    );
  }

  Widget _keyBtn(String text, [VoidCallback? onTap]) {
    return InkWell(
      onTap: onTap ?? () => _onDigit(text),
      child: Container(
        decoration: BoxDecoration(color: EverforestColors.bg1, border: Border.all(color: EverforestColors.bg2), borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: Text(text, style: const TextStyle(color: EverforestColors.fg, fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
