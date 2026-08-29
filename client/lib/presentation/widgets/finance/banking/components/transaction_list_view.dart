import 'package:flutter/material.dart';
import '../../../../../core/general_engine/general_engine_client.dart';
import '../../../../../theme/everforest_colors.dart';
import '../banking_models_and_helpers.dart';

class TransactionListView extends StatelessWidget {
  const TransactionListView({
    super.key,
    required this.transactions,
  });

  final List<GeneralEngineEntity> transactions;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Text('No transactions yet',
          style: TextStyle(color: EverforestColors.grey));
    }

    return Column(
      children: transactions.map((txEntity) {
        final tx = txEntity.payload;
        IconData icon = Icons.receipt_long;
        Color color = EverforestColors.grey;
        String cat = tx['category'] as String? ?? 'Other';
        if (cat == 'Groceries') {
          icon = Icons.shopping_cart_rounded;
          color = EverforestColors.orange;
        } else if (cat == 'Allowance') {
          icon = Icons.celebration_rounded;
          color = EverforestColors.purple;
        } else if (cat == 'Income') {
          icon = Icons.work_rounded;
          color = EverforestColors.green;
        } else if (cat == 'Bills') {
          icon = Icons.receipt_rounded;
          color = EverforestColors.red;
        }

        bool isIncome = tx['type'] == 'income';
        double amt = (tx['amount'] as num? ?? 0).toDouble();

        return _buildTransactionItem(
          icon: icon,
          iconColor: color,
          title: tx['title'] as String? ?? 'Untitled Transaction',
          category: cat,
          date: displayDate(tx['date']?.toString() ?? ''),
          amount: '${isIncome ? '+' : '-'}${fmtEuro(amt.abs())}',
          isIncome: isIncome,
        );
      }).toList(),
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String category,
    required String date,
    required String amount,
    bool isIncome = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: EverforestColors.bg0,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: EverforestColors.fg,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('$category • $date',
                    style: const TextStyle(
                        color: EverforestColors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: isIncome ? EverforestColors.green : EverforestColors.fg,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
