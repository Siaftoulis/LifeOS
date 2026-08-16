import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../theme/everforest_colors.dart';
import '../../../../core/general_engine/engine_repository.dart';
import '../../../../core/general_engine/general_engine_client.dart';
import '../../../../auth_service.dart';
import '../../../../api_client.dart';
import 'pdf_import_client.dart';

const _expenseCategories = ['Groceries', 'Allowance', 'Bills', 'Other'];

String _creatorId() =>
    AuthService.instance.currentUser.value?.username ?? 'panospds';

final ValueNotifier<int> _pointsTick = ValueNotifier(0);

String _fmtEuro(double v) =>
    NumberFormat.currency(locale: 'de_DE', symbol: '€').format(v);

String _monthLabel() => DateFormat('MMMM yyyy').format(DateTime.now());

String _isoDate(String? raw) {
  final now = DateFormat('yyyy-MM-dd').format(DateTime.now());
  if (raw == null || raw.isEmpty) return now;
  for (final f in ['dd/MM/yyyy', 'dd-MM-yyyy', 'dd.MM.yyyy', 'dd/MM/yy', 'dd-MM-yy', 'yyyy-MM-dd']) {
    try {
      return DateFormat('yyyy-MM-dd').format(DateFormat(f).parse(raw));
    } catch (_) {}
  }
  return now;
}

String _displayDate(String raw) {
  final d = DateTime.tryParse(raw);
  if (d != null) return DateFormat('MMM dd, yyyy').format(d);
  return raw;
}

class BankingDashboardView extends StatefulWidget {
  const BankingDashboardView({Key? key}) : super(key: key);

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
              const _StarsChip(),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: EverforestColors.green),
                onPressed: () => _showAddTransactionDialog(context),
              ),
              const SizedBox(width: 8),
              const CircleAvatar(
                backgroundColor: EverforestColors.bg2,
                child: Icon(Icons.person, color: EverforestColors.fg),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceCard(totalBalance, monthIncome, monthExpenses),
                const SizedBox(height: 24),
                _buildBudgetCard(
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
                ),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildSectionHeader('Recent Transactions', '${allTxs.length} Total'),
                const SizedBox(height: 16),
                _buildTransactionsList(allTxs),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- Budget ----------

  Widget _buildBudgetCard({
    required double income,
    required double totalBills,
    required double remaining,
    required double groceriesPct,
    required double savingsPct,
    required double allowancePct,
    required double groceries,
    required double savings,
    required double allowance,
    required double spentGroceries,
    required double spentAllowance,
    required List<GeneralEngineEntity> bills,
  }) {
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
              Text('Monthly Budget · ${_monthLabel()}',
                  style: const TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: EverforestColors.blue),
                onPressed: () => _showBudgetDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildBudgetRow('Monthly income', income),
          const Divider(color: EverforestColors.bg2, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bills', style: TextStyle(color: EverforestColors.grey)),
              TextButton(
                onPressed: () => _showAddBillDialog(context),
                child: const Text('+ Add', style: TextStyle(color: EverforestColors.green)),
              ),
            ],
          ),
          for (final bill in bills) _buildBillRow(bill),
          if (bills.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('No bills yet — add each bill amount when it arrives (email / app).',
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
                onPressed: () => _showBudgetDialog(context),
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
                  Expanded(flex: groceriesPct.toInt(), child: Container(height: 8, color: EverforestColors.orange)),
                  Expanded(flex: allowancePct.toInt(), child: Container(height: 8, color: EverforestColors.purple)),
                  Expanded(flex: savingsPct.toInt(), child: Container(height: 8, color: EverforestColors.green)),
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
          Text(_fmtEuro(amount),
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
                _award('+20 ⭐ Paid: ${bill.payload['name'] ?? 'bill'}');
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
          Text(_fmtEuro(_num(bill, 'amount')),
              style: const TextStyle(color: EverforestColors.fg, fontSize: 14)),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: EverforestColors.red),
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
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(color: EverforestColors.fg, fontSize: 13)),
          ),
          Text(
            spent > 0 ? '${_fmtEuro(spent)} spent · ' : '',
            style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
          ),
          Text('${_fmtEuro(left)} left',
              style: TextStyle(
                color: left < 0 ? EverforestColors.red : EverforestColors.green,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }

  // ---------- Balance card ----------

  Widget _buildBalanceCard(double balance, double monthIncome, double monthExpenses) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Balance',
                style: TextStyle(color: EverforestColors.grey, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: EverforestColors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _monthLabel(),
                  style: const TextStyle(color: EverforestColors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _fmtEuro(balance),
            style: const TextStyle(
              color: EverforestColors.fg,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildBalanceStat(
                  icon: Icons.arrow_downward,
                  iconColor: EverforestColors.green,
                  label: 'Income this month',
                  amount: _fmtEuro(monthIncome),
                ),
              ),
              Container(width: 1, height: 40, color: EverforestColors.bg2),
              Expanded(
                child: _buildBalanceStat(
                  icon: Icons.arrow_upward,
                  iconColor: EverforestColors.red,
                  label: 'Expenses this month',
                  amount: _fmtEuro(monthExpenses),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBalanceStat({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String amount,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: EverforestColors.grey, fontSize: 12)),
            const SizedBox(height: 2),
            Text(amount, style: const TextStyle(color: EverforestColors.fg, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  // ---------- Quick actions ----------

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionItem(
          icon: Icons.receipt_long,
          label: 'Receipt',
          color: EverforestColors.blue,
          onTap: () => _importReceipt(context),
        ),
        _buildActionItem(
          icon: Icons.download_rounded,
          label: 'Receive',
          color: EverforestColors.green,
          onTap: () => _showAddTransactionDialog(context, income: true),
        ),
        _buildActionItem(
          icon: Icons.account_balance_wallet_rounded,
          label: 'Bills',
          color: EverforestColors.purple,
          onTap: () => _showAddBillDialog(context),
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: EverforestColors.fg, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(action, style: const TextStyle(color: EverforestColors.blue, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ---------- Transactions list ----------

  Widget _buildTransactionsList(List<GeneralEngineEntity> transactions) {
    if (transactions.isEmpty) {
      return const Text('No transactions yet', style: TextStyle(color: EverforestColors.grey));
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
          date: _displayDate(tx['date']?.toString() ?? ''),
          amount: '${isIncome ? '+' : '-'}${_fmtEuro(amt.abs())}',
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
                Text(title, style: const TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('$category • $date', style: const TextStyle(color: EverforestColors.grey, fontSize: 12)),
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

  // ---------- Dialogs ----------

  Future<void> _showBudgetDialog(BuildContext context) async {
    final cfg = _budget(EngineRepository.instance.allEntities.value);
    final incomeController = TextEditingController(
        text: cfg != null ? _num(cfg, 'income').toStringAsFixed(2) : '');
    final gCtrl = TextEditingController(
        text: cfg != null ? _num(cfg, 'groceries_pct').toStringAsFixed(0) : '30');
    final sCtrl = TextEditingController(
        text: cfg != null ? _num(cfg, 'savings_pct').toStringAsFixed(0) : '20');
    final aCtrl = TextEditingController(
        text: cfg != null ? _num(cfg, 'allowance_pct').toStringAsFixed(0) : '50');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final g = double.tryParse(gCtrl.text.replaceAll(',', '.')) ?? 0;
          final s = double.tryParse(sCtrl.text.replaceAll(',', '.')) ?? 0;
          final a = double.tryParse(aCtrl.text.replaceAll(',', '.')) ?? 0;
          final sumsTo100 = (g + s + a) == 100;
          return AlertDialog(
            backgroundColor: EverforestColors.bg1,
            title: const Text('Monthly Budget', style: TextStyle(color: EverforestColors.fg)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(incomeController, 'Monthly income (€)'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _dialogField(gCtrl, 'Groceries %')),
                    const SizedBox(width: 8),
                    Expanded(child: _dialogField(sCtrl, 'Savings %')),
                    const SizedBox(width: 8),
                    Expanded(child: _dialogField(aCtrl, 'Allowance %')),
                  ],
                ),
                if (!sumsTo100)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Percentages must sum to 100',
                        style: TextStyle(color: EverforestColors.red, fontSize: 12)),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: EverforestColors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: EverforestColors.green),
                onPressed: sumsTo100 ? () => Navigator.pop(ctx, true) : null,
                child: const Text('Save', style: TextStyle(color: EverforestColors.bg0)),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true) return;

    final now = DateTime.now();
    final entity = GeneralEngineEntity(
      id: cfg?.id ?? const Uuid().v4(),
      type: 'budget_config',
      creatorId: _creatorId(),
      payload: {
        'month': _monthKey,
        'income': double.tryParse(incomeController.text.replaceAll(',', '.')) ?? 0,
        'groceries_pct': double.tryParse(gCtrl.text.replaceAll(',', '.')) ?? 30,
        'savings_pct': double.tryParse(sCtrl.text.replaceAll(',', '.')) ?? 20,
        'allowance_pct': double.tryParse(aCtrl.text.replaceAll(',', '.')) ?? 50,
      },
      sharedWith: cfg?.sharedWith ?? [],
      createdAt: cfg?.createdAt ?? now,
      updatedAt: now,
    );
    await EngineRepository.instance.saveEntity(entity);
    if (cfg == null) _award('+15 ⭐ Monthly budget set');
  }

  Future<void> _showAddBillDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EverforestColors.bg1,
        title: const Text('Add Bill', style: TextStyle(color: EverforestColors.fg)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(nameController, 'Name (e.g. ΔΕΗ, Vodafone, rent)'),
            const SizedBox(height: 12),
            _dialogField(amountController, 'Amount (€)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: EverforestColors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: EverforestColors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save', style: TextStyle(color: EverforestColors.bg0)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final name = nameController.text.trim();
    final amount = double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0;
    if (name.isEmpty || amount <= 0) return;

    final now = DateTime.now();
    final entity = GeneralEngineEntity(
      id: const Uuid().v4(),
      type: 'bill',
      creatorId: _creatorId(),
      payload: {'name': name, 'amount': amount, 'paid': false, 'month': _monthKey},
      sharedWith: [],
      createdAt: now,
      updatedAt: now,
    );
    await EngineRepository.instance.saveEntity(entity);
  }

  Future<void> _showAddTransactionDialog(BuildContext context, {bool income = false}) async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String category = income ? 'Income' : 'Groceries';
    String type = income ? 'income' : 'expense';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: EverforestColors.bg1,
          title: Text(income ? 'Receive Money' : 'Add Transaction',
              style: const TextStyle(color: EverforestColors.fg)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(titleController, 'Title'),
              const SizedBox(height: 12),
              _dialogField(amountController, 'Amount (€)'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                dropdownColor: EverforestColors.bg1,
                style: const TextStyle(color: EverforestColors.fg),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: EverforestColors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green)),
                ),
                items: (income ? const ['Income', 'Other'] : _expenseCategories)
                    .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: EverforestColors.fg))))
                    .toList(),
                onChanged: (v) => setDlgState(() => category = v ?? category),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: EverforestColors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: EverforestColors.green),
              onPressed: () async {
                final title = titleController.text.trim();
                final amt = double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0.0;
                if (title.isNotEmpty && amt > 0) {
                  final now = DateTime.now();
                  final entity = GeneralEngineEntity(
                    id: const Uuid().v4(),
                    type: 'bank_transaction',
                    creatorId: _creatorId(),
                    payload: {
                      'title': title,
                      'amount': amt,
                      'category': category,
                      'type': type,
                      'date': DateFormat('yyyy-MM-dd').format(now),
                    },
                    sharedWith: [],
                    createdAt: now,
                    updatedAt: now,
                  );
                  await EngineRepository.instance.saveEntity(entity);
                  _award(type == 'income' ? '+10 ⭐ Income recorded' : '+5 ⭐ Expense logged');
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save', style: TextStyle(color: EverforestColors.bg0)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: EverforestColors.fg),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: EverforestColors.grey),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green)),
      ),
    );
  }

  // ---------- PDF receipt import ----------

  Future<void> _importReceipt(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || result.files.single.bytes == null) return;

    final file = result.files.single;
    final parsed = await PdfImportClient.parseReceipt(file.bytes!, file.name);
    if (!mounted) return;
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read an amount from this PDF.')),
      );
      return;
    }

    String category = 'Other';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: EverforestColors.bg1,
          title: const Text('Receipt parsed', style: TextStyle(color: EverforestColors.fg)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${file.name}\n\nAmount: ${_fmtEuro(parsed.amount)}',
                  style: const TextStyle(color: EverforestColors.fg, fontSize: 15)),
              if (parsed.date.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Date: ${_displayDate(_isoDate(parsed.date))}',
                      style: const TextStyle(color: EverforestColors.grey, fontSize: 13)),
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                dropdownColor: EverforestColors.bg1,
                style: const TextStyle(color: EverforestColors.fg),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: EverforestColors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green)),
                ),
                items: _expenseCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: EverforestColors.fg))))
                    .toList(),
                onChanged: (v) => setDlgState(() => category = v ?? category),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: EverforestColors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: EverforestColors.green),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save', style: TextStyle(color: EverforestColors.bg0)),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    final now = DateTime.now();
    final entity = GeneralEngineEntity(
      id: const Uuid().v4(),
      type: 'bank_transaction',
      creatorId: _creatorId(),
      payload: {
        'title': parsed.title,
        'amount': parsed.amount,
        'category': category,
        'type': 'expense',
        'date': _isoDate(parsed.date),
      },
      sharedWith: [],
      createdAt: now,
      updatedAt: now,
    );
    await EngineRepository.instance.saveEntity(entity);
    _award('+5 ⭐ Receipt logged');
  }

  void _award(String msg) {
    if (!mounted) return;
    _pointsTick.value++;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: EverforestColors.bg2,
      ),
    );
  }
}

class _StarsChip extends StatefulWidget {
  const _StarsChip();

  @override
  State<_StarsChip> createState() => _StarsChipState();
}

class _StarsChipState extends State<_StarsChip> {
  int _points = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _fetch();
    _pointsTick.addListener(_fetch);
  }

  @override
  void dispose() {
    _pointsTick.removeListener(_fetch);
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      // ponytail: bus awards land a beat after the POST returns, so wait a tick
      await Future.delayed(const Duration(milliseconds: 600));
      final res = await ApiClient.instance.getDaemon('/api/v1/points/balance');
      if (mounted) {
        setState(() {
          _points = (res['points'] as num? ?? 0).toInt();
          _loaded = true;
        });
      }
    } catch (_) {
      // daemon unreachable — chip stays hidden
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: EverforestColors.yellow.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars, size: 14, color: EverforestColors.yellow),
          const SizedBox(width: 4),
          Text(
            '$_points',
            style: const TextStyle(
              color: EverforestColors.fg,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}