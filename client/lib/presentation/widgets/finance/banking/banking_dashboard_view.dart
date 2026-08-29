import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../theme/everforest_colors.dart';
import '../../../../core/general_engine/engine_repository.dart';
import '../../../../core/general_engine/general_engine_client.dart';
import 'banking_models_and_helpers.dart';
import 'components/balance_header_card.dart';
import 'components/budget_card_view.dart';
import 'components/category_analytics_card.dart';
import 'components/stars_chip.dart';
import 'components/transaction_list_view.dart';
import 'dialogs/banking_dialogs.dart';

export 'banking_models_and_helpers.dart';
export 'components/balance_header_card.dart';
export 'components/budget_card_view.dart';
export 'components/category_analytics_card.dart';
export 'components/stars_chip.dart';
export 'components/transaction_list_view.dart';
export 'dialogs/banking_dialogs.dart';

class BankingDashboardView extends StatefulWidget {
  const BankingDashboardView({super.key});

  @override
  State<BankingDashboardView> createState() => _BankingDashboardViewState();
}

class _BankingDashboardViewState extends State<BankingDashboardView> {
  String get _monthKey => DateFormat('yyyy-MM').format(DateTime.now());

  double _num(GeneralEngineEntity e, String key) =>
      (e.payload[key] as num? ?? 0).toDouble();

  GeneralEngineEntity? _budget(List<GeneralEngineEntity> entities) {
    for (final e in entities) {
      if (e.type == 'budget_config' && e.payload['month'] == _monthKey) return e;
    }
    return null;
  }

  List<GeneralEngineEntity> _monthBills(List<GeneralEngineEntity> entities) =>
      entities.where((e) =>
          e.type == 'bill' &&
          e.payload['month'] == _monthKey &&
          e.payload['deleted'] != true).toList();

  List<GeneralEngineEntity> _monthTxs(List<GeneralEngineEntity> entities) {
    final now = DateTime.now();
    return entities.where((e) {
      if (e.type != 'bank_transaction') return false;
      final d = DateTime.tryParse(e.payload['date']?.toString() ?? '');
      if (d == null) return true;
      return d.year == now.year && d.month == now.month;
    }).toList();
  }

  double _spent(List<GeneralEngineEntity> txs, String category) {
    var sum = 0.0;
    for (final t in txs) {
      if (t.payload['type'] == 'expense' && t.payload['category'] == category) {
        sum += _num(t, 'amount');
      }
    }
    return sum;
  }

  void _award(String msg) {
    if (!mounted) return;
    pointsTick.value++;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.stars, color: EverforestColors.yellow, size: 18),
            const SizedBox(width: 8),
            Text(msg, style: const TextStyle(color: EverforestColors.fg)),
          ],
        ),
        backgroundColor: EverforestColors.bg1,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<GeneralEngineEntity>>(
      valueListenable: EngineRepository.instance.allEntities,
      builder: (context, entities, child) {
        final accounts = EngineRepository.instance.bankAccounts;
        final allTxs = EngineRepository.instance.bankTransactions;
        final monthTxs = _monthTxs(entities);
        final bills = _monthBills(entities);
        final cfg = _budget(entities);

        final income = cfg != null ? _num(cfg, 'income') : 0.0;
        final groceriesPct = cfg != null ? _num(cfg, 'groceries_pct') : 30.0;
        final savingsPct = cfg != null ? _num(cfg, 'savings_pct') : 20.0;
        final allowancePct = cfg != null ? _num(cfg, 'allowance_pct') : 50.0;

        double totalBalance = 0.0;
        for (var acc in accounts) {
          totalBalance += _num(acc, 'balance');
        }
        if (accounts.isEmpty) {
          for (var tx in allTxs) {
            if (tx.payload['type'] == 'income') {
              totalBalance += _num(tx, 'amount');
            } else {
              totalBalance -= _num(tx, 'amount');
            }
          }
        }

        double monthIncome = 0, monthExpenses = 0;
        for (final t in monthTxs) {
          if (t.payload['type'] == 'income') {
            monthIncome += _num(t, 'amount');
          } else {
            monthExpenses += _num(t, 'amount');
          }
        }

        final totalBills = bills.fold(0.0, (s, b) => s + _num(b, 'amount'));
        final remaining = income - totalBills;
        final groceries = remaining * groceriesPct / 100;
        final savings = remaining * savingsPct / 100;
        final allowance = remaining * allowancePct / 100;

        return Scaffold(
          backgroundColor: EverforestColors.bg0,
          appBar: AppBar(
            backgroundColor: EverforestColors.bg0,
            elevation: 0,
            title: const Text(
              'Banking & Finance',
              style: TextStyle(
                color: EverforestColors.fg,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            actions: [
              const StarsChip(),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: EverforestColors.green),
                tooltip: 'Add Transaction',
                onPressed: () => BankingDialogs.showAddTransactionDialog(
                  context,
                  onAward: _award,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BalanceHeaderCard(
                  balance: totalBalance,
                  monthIncome: monthIncome,
                  monthExpenses: monthExpenses,
                ),
                const SizedBox(height: 20),
                QuickActionsRow(
                  onImportReceipt: () => BankingDialogs.importReceipt(
                    context,
                    onAward: _award,
                  ),
                  onReceiveMoney: () => BankingDialogs.showAddTransactionDialog(
                    context,
                    income: true,
                    onAward: _award,
                  ),
                  onAddBill: () => BankingDialogs.showAddBillDialog(
                    context,
                    monthKey: _monthKey,
                  ),
                ),
                const SizedBox(height: 24),
                CategoryAnalyticsCard(
                  monthTxs: monthTxs,
                  income: monthIncome > 0 ? monthIncome : income,
                ),
                const SizedBox(height: 24),
                BudgetCardView(
                  income: income,
                  totalBills: totalBills,
                  remaining: remaining,
                  groceriesPct: groceriesPct,
                  savingsPct: savingsPct,
                  allowancePct: allowancePct,
                  groceries: groceries,
                  savings: savings,
                  allowance: allowance,
                  spentGroceries: _spent(monthTxs, 'Groceries'),
                  spentAllowance: _spent(monthTxs, 'Allowance'),
                  bills: bills,
                  onEditBudget: () => BankingDialogs.showBudgetDialog(
                    context,
                    cfg: cfg,
                    monthKey: _monthKey,
                    onAward: _award,
                  ),
                  onAddBill: () => BankingDialogs.showAddBillDialog(
                    context,
                    monthKey: _monthKey,
                  ),
                  onAward: _award,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Transactions',
                        style: TextStyle(
                            color: EverforestColors.fg,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Text('${allTxs.length} Total',
                        style: const TextStyle(
                            color: EverforestColors.blue,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),
                TransactionListView(transactions: allTxs),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}