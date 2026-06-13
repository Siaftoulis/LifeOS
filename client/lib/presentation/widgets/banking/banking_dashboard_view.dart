import 'package:flutter/material.dart';
import 'budget_split_indicator.dart';
import 'ledger_transaction_card.dart';
import 'bill_pay_tracker_card.dart';

class BankingDashboardView extends StatelessWidget {
  const BankingDashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2d353b), // bg0
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Text(
                'BANKING CORE',
                style: TextStyle(
                  color: Color(0xFFd3c6aa),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Status: Syncing offline ledger...',
                style: TextStyle(color: Color(0xFF859289), fontSize: 12),
              ),
              const SizedBox(height: 24),
              
              // 1. Bill Round Up Tracker
              const BillPayTrackerCard(
                totalBillsCents: 18640,
                roundedTransferCents: 20000,
                rolloverSurplusCents: 1360,
              ),
              const SizedBox(height: 24),

              // 2. Budget Split
              const BudgetSplitIndicator(
                essentialsRatio: 0.50,
                savingsRatio: 0.20,
                personalRatio: 0.30,
              ),
              const SizedBox(height: 24),

              // 3. Recent Transactions
              const Text(
                'RECENT LEDGER',
                style: TextStyle(color: Color(0xFF859289), fontSize: 12, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: const [
                    LedgerTransactionCard(
                      title: 'Groceries (Sklavenitis)',
                      date: 'Oct 24, 2026',
                      amountCents: -5420,
                      type: 'Essentials',
                    ),
                    LedgerTransactionCard(
                      title: 'Salary Deposit',
                      date: 'Oct 20, 2026',
                      amountCents: 100000,
                      type: 'Income',
                    ),
                    LedgerTransactionCard(
                      title: 'Electricity Bill',
                      date: 'Oct 18, 2026',
                      amountCents: -18640,
                      type: 'Bills',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
