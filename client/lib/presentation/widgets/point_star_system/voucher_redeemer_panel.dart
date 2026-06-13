import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class VoucherRedeemerPanel extends StatelessWidget {
  const VoucherRedeemerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: EverforestColors.bg2, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Rewards Store', style: TextStyle(color: EverforestColors.fg, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5,
              children: const [
                _VoucherCard(title: '1 Hour TV/Netflix', cost: 50, color: EverforestColors.red),
                _VoucherCard(title: 'Stay Up 1hr Later', cost: 100, color: EverforestColors.blue),
                _VoucherCard(title: 'Pizza Night', cost: 300, color: EverforestColors.orange),
                _VoucherCard(title: 'Buy New Video Game', cost: 1000, color: EverforestColors.purple),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  final String title;
  final int cost;
  final Color color;

  const _VoucherCard({required this.title, required this.cost, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$cost Points', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 12)),
            onPressed: () {},
            child: const Text('Redeem', style: TextStyle(color: EverforestColors.bg0)),
          )
        ],
      ),
    );
  }
}
