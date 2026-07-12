import 'package:flutter/material.dart';

class GovCredentialCard extends StatelessWidget {
  final String label;
  final String? decryptedValue;
  final VoidCallback onTap;

  const GovCredentialCard({
    Key? key,
    required this.label,
    this.decryptedValue,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF343f44), // Everforest bg1
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3d484d), width: 1), // bg2
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFd3c6aa), // fg
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              decryptedValue ?? '•••••••••',
              style: TextStyle(
                color: decryptedValue != null 
                    ? const Color(0xFFa7c080) // accent green
                    : const Color(0xFF859289), // grey
                fontSize: 16,
                fontFamily: 'monospace',
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
