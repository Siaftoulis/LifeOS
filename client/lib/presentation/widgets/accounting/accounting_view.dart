import 'package:flutter/material.dart';
import 'gov_credential_card.dart';
import 'secure_document_card.dart';
import 'security_pin_curtain.dart';

class AccountingView extends StatefulWidget {
  const AccountingView({Key? key}) : super(key: key);

  @override
  State<AccountingView> createState() => _AccountingViewState();
}

class _AccountingViewState extends State<AccountingView> {
  bool _showPinCurtain = false;

  void _triggerPinCurtain() {
    setState(() {
      _showPinCurtain = true;
    });
  }

  void _onPinVerified(String pin) {
    setState(() {
      _showPinCurtain = false;
      // In a real scenario, this would trigger decryption API calls
    });
  }

  void _onPinCancelled() {
    setState(() {
      _showPinCurtain = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2d353b), // Everforest bg0
      appBar: AppBar(
        backgroundColor: const Color(0xFF343f44), // bg1
        title: const Text(
          'Accounting',
          style: TextStyle(color: Color(0xFFd3c6aa)), // fg
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                const Text(
                  'GOVERNMENT CREDENTIALS',
                  style: TextStyle(
                    color: Color(0xFF859289), // grey
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                GovCredentialCard(
                  label: 'Taxisnet',
                  onTap: _triggerPinCurtain,
                ),
                GovCredentialCard(
                  label: 'AMKA',
                  decryptedValue: '12345678901',
                  onTap: () {}, // Already decrypted stub
                ),
                const SizedBox(height: 32),
                const Text(
                  'SECURE DOCUMENTS',
                  style: TextStyle(
                    color: Color(0xFF859289), // grey
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    SecureDocumentCard(
                      title: 'ID Card Scan',
                      extension: 'pdf',
                      onTap: _triggerPinCurtain,
                    ),
                    SecureDocumentCard(
                      title: 'Tax Return 2025',
                      extension: 'png',
                      onTap: _triggerPinCurtain,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_showPinCurtain)
            SecurityPinCurtain(
              onVerified: _onPinVerified,
              onCancel: _onPinCancelled,
            ),
        ],
      ),
    );
  }
}
