import 'package:flutter/material.dart';

class LedgerTransactionCard extends StatelessWidget {
  final String title;
  final String date;
  final int amountCents;
  final String type;

  const LedgerTransactionCard({
    Key? key,
    required this.title,
    required this.date,
    required this.amountCents,
    required this.type,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isCredit = amountCents >= 0;
    final double euros = (amountCents / 100.0).abs();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF343f44), // bg1
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3d484d), width: 1), // bg2
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2d353b), // bg0
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isCredit ? const Color(0xFFa7c080) : const Color(0xFFe67e80), // green or red
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Color(0xFFd3c6aa), fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: const TextStyle(color: Color(0xFF859289), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          Text(
            '${isCredit ? '+' : '-'}€${euros.toStringAsFixed(2)}',
            style: TextStyle(
              color: isCredit ? const Color(0xFFa7c080) : const Color(0xFFd3c6aa),
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontFamily: 'JetBrainsMono',
            ),
          ),
        ],
      ),
    );
  }
}
