import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../theme/everforest_colors.dart';

class AccountingView extends StatefulWidget {
  const AccountingView({Key? key}) : super(key: key);

  @override
  State<AccountingView> createState() => _AccountingViewState();
}

class _AccountingViewState extends State<AccountingView> with SingleTickerProviderStateMixin {
  bool _showPinCurtain = false;
  late AnimationController _pinCurtainController;
  late Animation<double> _pinCurtainAnimation;

  @override
  void initState() {
    super.initState();
    _pinCurtainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pinCurtainAnimation = CurvedAnimation(
      parent: _pinCurtainController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pinCurtainController.dispose();
    super.dispose();
  }

  void _triggerPinCurtain() {
    setState(() => _showPinCurtain = true);
    _pinCurtainController.forward();
  }

  void _closePinCurtain() {
    _pinCurtainController.reverse().then((_) {
      setState(() => _showPinCurtain = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg0,
        elevation: 0,
        title: const Text(
          'Accounting & Tax',
          style: TextStyle(
            color: EverforestColors.fg,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: EverforestColors.green),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTaxSummaryCard(),
                const SizedBox(height: 24),
                _buildSectionHeader('Government Credentials'),
                const SizedBox(height: 16),
                _buildCredentialCard(
                  title: 'Taxisnet',
                  subtitle: 'Tax Authority Login',
                  isDecrypted: false,
                  onTap: _triggerPinCurtain,
                  icon: Icons.account_balance,
                  iconColor: EverforestColors.blue,
                ),
                _buildCredentialCard(
                  title: 'AMKA',
                  subtitle: 'Social Security Number',
                  decryptedValue: '12345678901',
                  isDecrypted: true,
                  onTap: () {},
                  icon: Icons.health_and_safety,
                  iconColor: EverforestColors.green,
                ),
                _buildCredentialCard(
                  title: 'EFKA',
                  subtitle: 'Insurance Portal',
                  isDecrypted: false,
                  onTap: _triggerPinCurtain,
                  icon: Icons.business_center,
                  iconColor: EverforestColors.purple,
                ),
                const SizedBox(height: 32),
                _buildSectionHeader('Secure Documents'),
                const SizedBox(height: 16),
                _buildDocumentGrid(),
              ],
            ),
          ),
          if (_showPinCurtain) _buildPinCurtain(),
        ],
      ),
    );
  }

  Widget _buildTaxSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            EverforestColors.bg1,
            EverforestColors.bg0,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: EverforestColors.bg2, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                'Estimated Tax Liability 2026',
                style: TextStyle(
                  color: EverforestColors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: EverforestColors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Pending',
                  style: TextStyle(color: EverforestColors.red, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '€3,240.50',
            style: TextStyle(
              color: EverforestColors.fg,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildTaxDetail(label: 'Gross Income', amount: '€28,500'),
              ),
              Container(width: 1, height: 30, color: EverforestColors.bg2),
              Expanded(
                child: _buildTaxDetail(label: 'Deductibles', amount: '€4,200', amountColor: EverforestColors.green),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTaxDetail({required String label, required String amount, Color? amountColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(color: EverforestColors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            color: amountColor ?? EverforestColors.fg,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: EverforestColors.grey,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildCredentialCard({
    required String title,
    required String subtitle,
    required bool isDecrypted,
    required VoidCallback onTap,
    required IconData icon,
    required Color iconColor,
    String? decryptedValue,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EverforestColors.bg1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EverforestColors.bg2, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
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
                    subtitle,
                    style: const TextStyle(
                      color: EverforestColors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isDecrypted)
              Text(
                decryptedValue ?? '',
                style: const TextStyle(
                  color: EverforestColors.green,
                  fontSize: 16,
                  fontFamily: 'monospace',
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: EverforestColors.bg2,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, size: 14, color: EverforestColors.grey),
                    SizedBox(width: 4),
                    Text(
                      'UNLOCK',
                      style: TextStyle(
                        color: EverforestColors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.85,
      children: [
        _buildDocumentCard(
          title: 'National ID',
          date: 'Updated Jan 2026',
          icon: Icons.badge_outlined,
          color: EverforestColors.blue,
        ),
        _buildDocumentCard(
          title: 'Tax Return 2025',
          date: 'E1 Form • PDF',
          icon: Icons.description_outlined,
          color: EverforestColors.green,
        ),
        _buildDocumentCard(
          title: 'Vehicle Reg',
          date: 'License Plate • PDF',
          icon: Icons.directions_car_outlined,
          color: EverforestColors.yellow,
        ),
        _buildDocumentCard(
          title: 'Property Tax',
          date: 'ENFIA 2026',
          icon: Icons.home_work_outlined,
          color: EverforestColors.orange,
        ),
      ],
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String date,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: _triggerPinCurtain,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EverforestColors.bg1,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: EverforestColors.bg2, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: EverforestColors.fg,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: const TextStyle(
                color: EverforestColors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinCurtain() {
    return AnimatedBuilder(
      animation: _pinCurtainAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Backdrop blur
            Positioned.fill(
              child: GestureDetector(
                onTap: _closePinCurtain,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 10 * _pinCurtainAnimation.value,
                    sigmaY: 10 * _pinCurtainAnimation.value,
                  ),
                  child: Container(
                    color: Colors.black.withOpacity(0.4 * _pinCurtainAnimation.value),
                  ),
                ),
              ),
            ),
            // Pin dialog
            Align(
              alignment: Alignment.center,
              child: Transform.scale(
                scale: 0.9 + (0.1 * _pinCurtainAnimation.value),
                child: Opacity(
                  opacity: _pinCurtainAnimation.value,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: EverforestColors.bg0,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: EverforestColors.bg2, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_person_outlined, color: EverforestColors.green, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'Authentication Required',
                          style: TextStyle(
                            color: EverforestColors.fg,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please enter your secure PIN to access this document.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: EverforestColors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(4, (index) => _buildPinDot()),
                        ),
                        const SizedBox(height: 32),
                        TextButton(
                          onPressed: _closePinCurtain,
                          child: const Text('CANCEL', style: TextStyle(color: EverforestColors.grey)),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPinDot() {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        color: EverforestColors.bg2,
        shape: BoxShape.circle,
      ),
    );
  }
}
