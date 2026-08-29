import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/general_engine/engine_repository.dart';
import '../../../../../core/general_engine/general_engine_client.dart';
import '../../../../../theme/everforest_colors.dart';
import '../banking_models_and_helpers.dart';
import '../pdf_import_client.dart';

class BankingDialogs {
  static Widget dialogField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: EverforestColors.fg),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: EverforestColors.grey),
        enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: EverforestColors.bg2)),
        focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: EverforestColors.green)),
      ),
    );
  }

  static Future<void> showBudgetDialog(
    BuildContext context, {
    required GeneralEngineEntity? cfg,
    required String monthKey,
    required void Function(String msg) onAward,
  }) async {
    final incomeController = TextEditingController(
        text: cfg != null
            ? (cfg.payload['income'] as num? ?? 0).toDouble().toStringAsFixed(2)
            : '');
    final gCtrl = TextEditingController(
        text: cfg != null
            ? (cfg.payload['groceries_pct'] as num? ?? 30).toDouble().toStringAsFixed(0)
            : '30');
    final sCtrl = TextEditingController(
        text: cfg != null
            ? (cfg.payload['savings_pct'] as num? ?? 20).toDouble().toStringAsFixed(0)
            : '20');
    final aCtrl = TextEditingController(
        text: cfg != null
            ? (cfg.payload['allowance_pct'] as num? ?? 50).toDouble().toStringAsFixed(0)
            : '50');

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
            title: const Text('Monthly Budget',
                style: TextStyle(color: EverforestColors.fg)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                dialogField(incomeController, 'Monthly income (€)'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: dialogField(gCtrl, 'Groceries %')),
                    const SizedBox(width: 8),
                    Expanded(child: dialogField(sCtrl, 'Savings %')),
                    const SizedBox(width: 8),
                    Expanded(child: dialogField(aCtrl, 'Allowance %')),
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
                child: const Text('Cancel',
                    style: TextStyle(color: EverforestColors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: EverforestColors.green),
                onPressed: sumsTo100 ? () => Navigator.pop(ctx, true) : null,
                child: const Text('Save',
                    style: TextStyle(color: EverforestColors.bg0)),
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
      creatorId: creatorId(),
      payload: {
        'month': monthKey,
        'income':
            double.tryParse(incomeController.text.replaceAll(',', '.')) ?? 0,
        'groceries_pct': double.tryParse(gCtrl.text.replaceAll(',', '.')) ?? 30,
        'savings_pct': double.tryParse(sCtrl.text.replaceAll(',', '.')) ?? 20,
        'allowance_pct': double.tryParse(aCtrl.text.replaceAll(',', '.')) ?? 50,
      },
      sharedWith: cfg?.sharedWith ?? [],
      createdAt: cfg?.createdAt ?? now,
      updatedAt: now,
    );
    await EngineRepository.instance.saveEntity(entity);
    if (cfg == null) onAward('+15 ⭐ Monthly budget set');
  }

  static Future<void> showAddBillDialog(
    BuildContext context, {
    required String monthKey,
  }) async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EverforestColors.bg1,
        title:
            const Text('Add Bill', style: TextStyle(color: EverforestColors.fg)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            dialogField(nameController, 'Name (e.g. ΔΕΗ, Vodafone, rent)'),
            const SizedBox(height: 12),
            dialogField(amountController, 'Amount (€)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: EverforestColors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: EverforestColors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save',
                style: TextStyle(color: EverforestColors.bg0)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final name = nameController.text.trim();
    final amount =
        double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0;
    if (name.isEmpty || amount <= 0) return;

    final now = DateTime.now();
    final entity = GeneralEngineEntity(
      id: const Uuid().v4(),
      type: 'bill',
      creatorId: creatorId(),
      payload: {
        'name': name,
        'amount': amount,
        'paid': false,
        'month': monthKey
      },
      sharedWith: [],
      createdAt: now,
      updatedAt: now,
    );
    await EngineRepository.instance.saveEntity(entity);
  }

  static Future<void> showAddTransactionDialog(
    BuildContext context, {
    bool income = false,
    required void Function(String msg) onAward,
  }) async {
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
              TextField(
                controller: titleController,
                style: const TextStyle(color: EverforestColors.fg),
                decoration: const InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: EverforestColors.grey),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: EverforestColors.bg2)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: EverforestColors.green)),
                ),
              ),
              const SizedBox(height: 12),
              dialogField(amountController, 'Amount (€)'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                dropdownColor: EverforestColors.bg1,
                style: const TextStyle(color: EverforestColors.fg),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: EverforestColors.grey),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: EverforestColors.bg2)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: EverforestColors.green)),
                ),
                items: (income ? const ['Income', 'Other'] : expenseCategories)
                    .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c,
                            style:
                                const TextStyle(color: EverforestColors.fg))))
                    .toList(),
                onChanged: (v) => setDlgState(() => category = v ?? category),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: EverforestColors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: EverforestColors.green),
              onPressed: () async {
                final title = titleController.text.trim();
                final amt =
                    double.tryParse(amountController.text.replaceAll(',', '.')) ??
                        0.0;
                if (title.isNotEmpty && amt > 0) {
                  final now = DateTime.now();
                  final entity = GeneralEngineEntity(
                    id: const Uuid().v4(),
                    type: 'bank_transaction',
                    creatorId: creatorId(),
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
                  onAward(type == 'income'
                      ? '+10 ⭐ Income recorded'
                      : '+5 ⭐ Expense logged');
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save',
                  style: TextStyle(color: EverforestColors.bg0)),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> importReceipt(
    BuildContext context, {
    required void Function(String msg) onAward,
  }) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null ||
        result.files.isEmpty ||
        result.files.single.bytes == null) return;

    final file = result.files.single;
    final parsed = await PdfImportClient.parseReceipt(file.bytes!, file.name);
    if (!context.mounted) return;
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
          title: const Text('Receipt parsed',
              style: TextStyle(color: EverforestColors.fg)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${file.name}\n\nAmount: ${fmtEuro(parsed.amount)}',
                  style: const TextStyle(
                      color: EverforestColors.fg, fontSize: 15)),
              if (parsed.date.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Date: ${displayDate(isoDate(parsed.date))}',
                      style: const TextStyle(
                          color: EverforestColors.grey, fontSize: 13)),
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                dropdownColor: EverforestColors.bg1,
                style: const TextStyle(color: EverforestColors.fg),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: EverforestColors.grey),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: EverforestColors.bg2)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: EverforestColors.green)),
                ),
                items: expenseCategories
                    .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c,
                            style:
                                const TextStyle(color: EverforestColors.fg))))
                    .toList(),
                onChanged: (v) => setDlgState(() => category = v ?? category),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: EverforestColors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: EverforestColors.green),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save',
                  style: TextStyle(color: EverforestColors.bg0)),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final now = DateTime.now();
    final entity = GeneralEngineEntity(
      id: const Uuid().v4(),
      type: 'bank_transaction',
      creatorId: creatorId(),
      payload: {
        'title': parsed.title,
        'amount': parsed.amount,
        'category': category,
        'type': 'expense',
        'date': isoDate(parsed.date),
      },
      sharedWith: [],
      createdAt: now,
      updatedAt: now,
    );
    await EngineRepository.instance.saveEntity(entity);
    onAward('+5 ⭐ Receipt logged');
  }
}
