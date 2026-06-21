import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class BankingDashboardView extends StatelessWidget {
  const BankingDashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg0,
        elevation: 0,
        title: const Text(
          'Banking',
          style: TextStyle(
            color: EverforestColors.fg,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: EverforestColors.fg),
            onPressed: () {},
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
            _buildBalanceCard(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildSectionHeader('Budget Overview', 'Details'),
            const SizedBox(height: 16),
            _buildBudgetSplit(),
            const SizedBox(height: 24),
            _buildSectionHeader('Recent Transactions', 'View All'),
            const SizedBox(height: 16),
            _buildTransactionsList(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
                style: TextStyle(
                  color: EverforestColors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: EverforestColors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_upward, size: 14, color: EverforestColors.green),
                    SizedBox(width: 4),
                    Text(
                      '+2.4%',
                      style: TextStyle(
                        color: EverforestColors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '\$12,450.80',
            style: TextStyle(
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
                  label: 'Income',
                  amount: '\$4,200.00',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: EverforestColors.bg2,
              ),
              Expanded(
                child: _buildBalanceStat(
                  icon: Icons.arrow_upward,
                  iconColor: EverforestColors.red,
                  label: 'Expenses',
                  amount: '\$1,850.20',
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
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: EverforestColors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              amount,
              style: const TextStyle(
                color: EverforestColors.fg,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionItem(icon: Icons.send_rounded, label: 'Send', color: EverforestColors.blue),
        _buildActionItem(icon: Icons.download_rounded, label: 'Receive', color: EverforestColors.green),
        _buildActionItem(icon: Icons.account_balance_wallet_rounded, label: 'Bills', color: EverforestColors.purple),
        _buildActionItem(icon: Icons.more_horiz_rounded, label: 'More', color: EverforestColors.orange),
      ],
    );
  }

  Widget _buildActionItem({required IconData icon, required String label, required Color color}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: EverforestColors.fg,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: EverforestColors.fg,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          action,
          style: const TextStyle(
            color: EverforestColors.blue,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetSplit() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Monthly Limit', style: TextStyle(color: EverforestColors.grey)),
              Text('\$3,000', style: TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(flex: 50, child: Container(height: 8, color: EverforestColors.blue)),
                Expanded(flex: 30, child: Container(height: 8, color: EverforestColors.green)),
                Expanded(flex: 20, child: Container(height: 8, color: EverforestColors.purple)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendItem(color: EverforestColors.blue, label: 'Needs (50%)'),
              _buildLegendItem(color: EverforestColors.green, label: 'Wants (30%)'),
              _buildLegendItem(color: EverforestColors.purple, label: 'Savings (20%)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: EverforestColors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildTransactionsList() {
    return Column(
      children: [
        _buildTransactionItem(
          icon: Icons.shopping_cart_rounded,
          iconColor: EverforestColors.orange,
          title: 'Whole Foods Market',
          category: 'Groceries',
          date: 'Today, 10:45 AM',
          amount: '-\$145.20',
        ),
        _buildTransactionItem(
          icon: Icons.movie_rounded,
          iconColor: EverforestColors.purple,
          title: 'Netflix Subscription',
          category: 'Entertainment',
          date: 'Yesterday',
          amount: '-\$15.99',
        ),
        _buildTransactionItem(
          icon: Icons.work_rounded,
          iconColor: EverforestColors.green,
          title: 'Salary Deposit',
          category: 'Income',
          date: 'Oct 20, 2026',
          amount: '+\$4,200.00',
          isIncome: true,
        ),
        _buildTransactionItem(
          icon: Icons.flash_on_rounded,
          iconColor: EverforestColors.yellow,
          title: 'Electric Bill',
          category: 'Utilities',
          date: 'Oct 18, 2026',
          amount: '-\$85.00',
        ),
      ],
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
                Text(
                  title,
                  style: const TextStyle(
                    color: EverforestColors.fg,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$category • $date',
                  style: const TextStyle(
                    color: EverforestColors.grey,
                    fontSize: 12,
                  ),
                ),
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
