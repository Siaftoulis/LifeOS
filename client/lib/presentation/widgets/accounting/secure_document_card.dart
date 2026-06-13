import 'package:flutter/material.dart';

class SecureDocumentCard extends StatelessWidget {
  final String title;
  final String extension;
  final VoidCallback onTap;

  const SecureDocumentCard({
    Key? key,
    required this.title,
    required this.extension,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF343f44), // bg1
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3d484d), width: 1), // bg2
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              color: Color(0xFF859289), // grey
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFd3c6aa), // fg
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2d353b), // bg0
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                extension.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFa7c080), // accent
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
