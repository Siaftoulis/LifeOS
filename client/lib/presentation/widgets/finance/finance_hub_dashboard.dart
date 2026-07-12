import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'accounting/accounting_view.dart';
import 'banking/banking_dashboard_view.dart';

class FinanceHubDashboard extends StatelessWidget {
  const FinanceHubDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: EverforestColors.bg0,
        appBar: AppBar(
          backgroundColor: EverforestColors.bg1,
          title: const Text('Finance Hub', style: TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold)),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Banking & Ledger'),
              Tab(text: 'Accounting & Tax'),
            ],
            labelColor: EverforestColors.green,
            unselectedLabelColor: EverforestColors.grey,
            indicatorColor: EverforestColors.green,
          ),
        ),
        body: const TabBarView(
          physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          children: [
            BankingDashboardView(),
            AccountingView(),
          ],
        ),
      ),
    );
  }
}
