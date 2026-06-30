import 'package:flutter/material.dart';
import '../../../../theme/everforest_colors.dart';
import '../../../database/database.dart';

class QuestRewardStore extends StatelessWidget {
  final Stream<List<Voucher>> vouchersStream;

  const QuestRewardStore({super.key, required this.vouchersStream});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('REWARD STORE', style: TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 24),
        StreamBuilder<List<Voucher>>(
          stream: vouchersStream,
          builder: (context, snapshot) {
            final vouchers = snapshot.data ?? [];
            if (vouchers.isEmpty) return const Center(child: Text("No rewards available.", style: TextStyle(color: EverforestColors.grey)));

            return Column(
              children: vouchers.map((voucher) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: EverforestColors.grey.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(voucher.title, style: const TextStyle(color: EverforestColors.fg, fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          const Text('Redeem reward', style: TextStyle(color: EverforestColors.grey, fontSize: 12)),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                           // Call points dao to redeem
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: EverforestColors.yellow.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: EverforestColors.yellow, width: 1),
                          ),
                          child: Text('${voucher.costPoints} ★', style: const TextStyle(color: EverforestColors.yellow, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              )).toList(),
            );
          }
        ),
      ],
    );
  }
}
