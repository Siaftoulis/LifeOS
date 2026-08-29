import 'package:flutter/material.dart';
import '../../../../../core/general_engine/general_engine_client.dart';
import '../../../../../theme/everforest_colors.dart';

class CategoryAnalyticsCard extends StatelessWidget {
  const CategoryAnalyticsCard({
    super.key,
    required this.monthTxs,
    required this.income,
  });

  final List<GeneralEngineEntity> monthTxs;
  final double income;

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'groceries':
        return EverforestColors.green;
      case 'utilities':
        return EverforestColors.blue;
      case 'dining':
        return EverforestColors.orange;
      case 'transport':
        return EverforestColors.yellow;
      case 'entertainment':
        return EverforestColors.purple;
      case 'health':
        return EverforestColors.red;
      case 'shopping':
        return EverforestColors.aqua;
      default:
        return EverforestColors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'groceries':
        return Icons.shopping_cart_rounded;
      case 'utilities':
        return Icons.bolt_rounded;
      case 'dining':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'entertainment':
        return Icons.sports_esports_rounded;
      case 'health':
        return Icons.medical_services_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, double> categorySums = {};
    double totalExpenses = 0.0;

    for (final tx in monthTxs) {
      if (tx.payload['type'] == 'expense') {
        final cat = tx.payload['category']?.toString() ?? 'Other';
        final amount = (tx.payload['amount'] as num? ?? 0).toDouble();
        categorySums[cat] = (categorySums[cat] ?? 0.0) + amount;
        totalExpenses += amount;
      }
    }

    final sortedEntries = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final netSavings = income - totalExpenses;

    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Monthly Cash Flow Overview
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Spending Analytics',
                style: TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (netSavings >= 0
                          ? EverforestColors.green
                          : EverforestColors.red)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  netSavings >= 0
                      ? '+€${netSavings.toStringAsFixed(0)} Net'
                      : '-€${(-netSavings).toStringAsFixed(0)} Deficit',
                  style: TextStyle(
                    color: netSavings >= 0
                        ? EverforestColors.green
                        : EverforestColors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2 KPI metric pills: Total Spent vs Total Income
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: EverforestColors.bg0,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Spent',
                        style: TextStyle(color: EverforestColors.grey, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '€${totalExpenses.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: EverforestColors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: EverforestColors.bg0,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monthly Income',
                        style: TextStyle(color: EverforestColors.grey, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '€${income.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: EverforestColors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Categories Breakdown List
          if (sortedEntries.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No expenses logged this month',
                  style: TextStyle(color: EverforestColors.grey, fontSize: 13),
                ),
              ),
            )
          else ...[
            const Text(
              'CATEGORY BREAKDOWN',
              style: TextStyle(
                color: EverforestColors.grey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            ...sortedEntries.map((entry) {
              final cat = entry.key;
              final sum = entry.value;
              final pct = totalExpenses > 0 ? (sum / totalExpenses) : 0.0;
              final color = _getCategoryColor(cat);
              final icon = _getCategoryIcon(cat);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: color, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          cat,
                          style: const TextStyle(
                            color: EverforestColors.fg,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '€${sum.toStringAsFixed(2)} (${(pct * 100).toStringAsFixed(0)}%)',
                          style: const TextStyle(
                            color: EverforestColors.fg,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: EverforestColors.bg0,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
