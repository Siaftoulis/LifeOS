import 'package:flutter/material.dart';
import 'accounting/accounting_view.dart';
import 'banking/banking_dashboard_view.dart';

import '../../../theme/app_skin_manager.dart';

class FinanceHubDashboard extends StatelessWidget {
  const FinanceHubDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSkinManager.currentSkinNotifier,
      builder: (context, _) {
        final skin = context.skin;
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: skin.bg0,
            appBar: AppBar(
              backgroundColor: skin.bg1,
              title: Text('Finance Hub', style: TextStyle(color: skin.fg, fontWeight: FontWeight.bold)),
              elevation: 0,
              bottom: TabBar(
                tabs: const [
                  Tab(text: 'Banking & Ledger'),
                  Tab(text: 'Accounting & Tax'),
                ],
                labelColor: skin.accent,
                unselectedLabelColor: skin.textMuted,
                indicatorColor: skin.accent,
              ),
            ),
            body: TabBarView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              children: [
                KeyedSubtree(
                  key: ValueKey('banking_${skin.id}'),
                  child: const BankingDashboardView(),
                ),
                KeyedSubtree(
                  key: ValueKey('accounting_${skin.id}'),
                  child: const AccountingView(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
