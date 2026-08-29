import 'package:flutter/material.dart';
import '../../../../../core/general_engine/engine_repository.dart';
import '../../../../../core/general_engine/general_engine_client.dart';
import '../../../../../theme/everforest_colors.dart';
import '../banking_models_and_helpers.dart';

class BudgetCardView extends StatelessWidget {
  const BudgetCardView({
    super.key,
    required this.income,
    required this.totalBills,
    required this.remaining,
    required this.groceriesPct,
    required this.savingsPct,
    required this.allowancePct,
    required this.groceries,
    required this.savings,
    required this.allowance,
    required this.spentGroceries,
    required this.spentAllowance,
    required this.bills,
    required this.onEditBudget,
    required this.onAddBill,
    required this.onAward,
  });

  final double income;
  final double totalBills;
  final double remaining;
  final double groceriesPct;
  final double savingsPct;
  final double allowancePct;
  final double groceries;
  final double savings;
  final double allowance;
  final double spentGroceries;
  final double spentAllowance;
  final List<GeneralEngineEntity> bills;
  final VoidCallback onEditBudget;
  final VoidCallback onAddBill;
  final void Function(String msg) onAward;

  double _num(GeneralEngineEntity e, String key) =>
      (e.payload[key] as num? ?? 0).toDouble();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Budget · ${monthLabel()}',
                  style: const TextStyle(
                      color: EverforestColors.fg,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.edit,
                    size: 18, color: EverforestColors.blue),
                onPressed: onEditBudget,
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildBudgetRow('Monthly income', income),
          const Divider(color: EverforestColors.bg2, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bills',
                  style: TextStyle(color: EverforestColors.grey)),
              TextButton(
                onPressed: onAddBill,
                child: const Text('+ Add',
                    style: TextStyle(color: EverforestColors.green)),
              ),
            ],
          ),
          for (final bill in bills) _buildBillRow(bill),
          if (bills.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                  'No bills yet — add each bill amount when it arrives (email / app).',
                  style: TextStyle(color: EverforestColors.grey, fontSize: 12)),
            ),
          _buildBudgetRow('Total bills', totalBills),
          const SizedBox(height: 8),
          _buildBudgetRow('Remaining', remaining, bold: true),
          const SizedBox(height: 16),
          if (income <= 0)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onEditBudget,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: EverforestColors.green),
                  foregroundColor: EverforestColors.green,
                ),
                child: const Text('Set monthly income'),
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Expanded(
                      flex: groceriesPct.toInt(),
                      child:
                          Container(height: 8, color: EverforestColors.orange)),
                  Expanded(
                      flex: allowancePct.toInt(),
                      child:
                          Container(height: 8, color: EverforestColors.purple)),
                  Expanded(
                      flex: savingsPct.toInt(),
                      child:
                          Container(height: 8, color: EverforestColors.green)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildBucketRow(
              color: EverforestColors.orange,
              label: 'Groceries (${groceriesPct.toStringAsFixed(0)}%)',
              budget: groceries,
              spent: spentGroceries,
            ),
            _buildBucketRow(
              color: EverforestColors.purple,
              label: 'Allowance (${allowancePct.toStringAsFixed(0)}%)',
              budget: allowance,
              spent: spentAllowance,
            ),
            _buildBucketRow(
              color: EverforestColors.green,
              label: 'Savings (${savingsPct.toStringAsFixed(0)}%)',
              budget: savings,
              spent: 0,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBudgetRow(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                color: EverforestColors.grey,
                fontSize: 14,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              )),
          Text(fmtEuro(amount),
              style: TextStyle(
                color: EverforestColors.fg,
                fontSize: 14,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              )),
        ],
      ),
    );
  }

  Widget _buildBillRow(GeneralEngineEntity bill) {
    final paid = bill.payload['paid'] == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              bill.payload['paid'] = !paid;
              EngineRepository.instance.saveEntity(bill);
              if (!paid) {
                onAward('+20 ⭐ Paid: ${bill.payload['name'] ?? 'bill'}');
              }
            },
            child: Icon(
              paid ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 20,
              color: paid ? EverforestColors.green : EverforestColors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              bill.payload['name']?.toString() ?? 'Bill',
              style: TextStyle(
                color: paid ? EverforestColors.grey : EverforestColors.fg,
                fontSize: 14,
                decoration: paid ? TextDecoration.lineThrough : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(fmtEuro(_num(bill, 'amount')),
              style: const TextStyle(color: EverforestColors.fg, fontSize: 14)),
          IconButton(
            icon:
                const Icon(Icons.close, size: 16, color: EverforestColors.red),
            onPressed: () {
              bill.payload['deleted'] = true;
              EngineRepository.instance.saveEntity(bill);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBucketRow({
    required Color color,
    required String label,
    required double budget,
    required double spent,
  }) {
    final left = budget - spent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style:
                    const TextStyle(color: EverforestColors.fg, fontSize: 13)),
          ),
          Text(
            spent > 0 ? '${fmtEuro(spent)} spent · ' : '',
            style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
          ),
          Text('${fmtEuro(left)} left',
              style: TextStyle(
                color: left < 0 ? EverforestColors.red : EverforestColors.green,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }
}
