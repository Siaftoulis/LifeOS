import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import '../../../theme/everforest_colors.dart';
import '../../../database/database.dart';
import '../../../api_client.dart';

class VoucherRedeemerPanel extends StatelessWidget {
  const VoucherRedeemerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return StreamBuilder<SystemUser?>(
      stream: AppDatabase.instance.homeScreenDao.watchCurrentUser(),
      builder: (context, userSnapshot) {
        final currentUser = userSnapshot.data;
        final currentPoints = currentUser?.currentPoints ?? 0;

        return StreamBuilder<List<Voucher>>(
          stream: AppDatabase.instance.pointsDao.watchAllVouchers(),
          builder: (context, voucherSnapshot) {
            if (!voucherSnapshot.hasData) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.7,
                decoration: const BoxDecoration(
                  color: EverforestColors.bg0,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const Center(child: CircularProgressIndicator(color: EverforestColors.purple)),
              );
            }
            final vouchers = voucherSnapshot.data!;

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Rewards Store', style: TextStyle(color: EverforestColors.fg, fontSize: 24, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: EverforestColors.bg1,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: EverforestColors.yellow.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: EverforestColors.yellow, size: 18),
                            const SizedBox(width: 4),
                            Text('$currentPoints pts', style: const TextStyle(color: EverforestColors.yellow, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: vouchers.isEmpty
                        ? const Center(child: Text('No vouchers available', style: TextStyle(color: EverforestColors.grey)))
                        : GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isMobile ? 1 : 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: isMobile ? 3.5 : 2.5,
                            ),
                            itemCount: vouchers.length,
                            itemBuilder: (context, index) {
                              final voucher = vouchers[index];
                              return _VoucherCard(
                                voucher: voucher,
                                currentUser: currentUser,
                                onRedeem: currentUser != null
                                    ? () => _redeemVoucher(context, currentUser, voucher)
                                    : null,
                              );
                            },
                          ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _redeemVoucher(BuildContext context, SystemUser user, Voucher voucher) async {
    if (user.currentPoints < voucher.costPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough points!', style: TextStyle(color: Colors.white)),
          backgroundColor: EverforestColors.red,
        ),
      );
      return;
    }

    try {
      final db = AppDatabase.instance;

      // Update user points locally
      final updatedUser = user.copyWith(
        currentPoints: user.currentPoints - voucher.costPoints,
        updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        isDirty: 1,
      );
      await db.pointsDao.updateUser(updatedUser);

      // Insert transaction ledger log locally
      final ledgerId = "l-redeem-${DateTime.now().millisecondsSinceEpoch}";
      await db.pointsDao.insertLedger(PointsLedgersCompanion.insert(
        id: ledgerId,
        userId: user.id,
        event: 'Redeemed ${voucher.title}',
        points: -voucher.costPoints,
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        isDirty: const Value(1),
      ));

      // Mark voucher as redeemed locally
      final updatedVoucher = voucher.copyWith(
        isRedeemed: 1,
        redeemedBy: Value(user.id),
        isDirty: 1,
      );
      await db.update(db.vouchers).replace(updatedVoucher);

      // Forward transaction to daemon API in background (fire-and-forget, fallback to sync queue)
      try {
        await ApiClient.instance.postDaemon('/api/v1/points/vouchers/redeem', {
          'voucher_id': voucher.id,
          'user_id': user.id,
        });
      } catch (_) {}

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully redeemed: ${voucher.title}!', style: const TextStyle(color: Colors.white)),
            backgroundColor: EverforestColors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Redemption failed: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: EverforestColors.red,
          ),
        );
      }
    }
  }
}

class _VoucherCard extends StatelessWidget {
  final Voucher voucher;
  final SystemUser? currentUser;
  final VoidCallback? onRedeem;

  const _VoucherCard({
    required this.voucher,
    required this.currentUser,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    if (voucher.costPoints < 100) {
      color = EverforestColors.blue;
    } else if (voucher.costPoints < 300) {
      color = EverforestColors.orange;
    } else if (voucher.costPoints < 1000) {
      color = EverforestColors.purple;
    } else {
      color = EverforestColors.red;
    }

    final isRedeemed = voucher.isRedeemed == 1;

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
                Text(
                  voucher.title,
                  style: TextStyle(
                    color: EverforestColors.fg,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: isRedeemed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${voucher.costPoints} Points', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isRedeemed ? EverforestColors.bg2 : color,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: isRedeemed ? null : onRedeem,
            child: Text(
              isRedeemed ? 'Redeemed' : 'Redeem',
              style: TextStyle(color: isRedeemed ? EverforestColors.grey : EverforestColors.bg0),
            ),
          )
        ],
      ),
    );
  }
}
