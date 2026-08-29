import 'package:flutter/material.dart';
import '../../../core/repositories/prayer_repository.dart';
import '../../../theme/everforest_colors.dart';

class SynaxarionDetailSheet extends StatelessWidget {
  const SynaxarionDetailSheet({
    super.key,
    required this.saint,
    required this.dateFormatted,
  });

  final SaintModel saint;
  final String dateFormatted;

  static Future<void> show(
    BuildContext context, {
    required SaintModel saint,
    required String dateFormatted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SynaxarionDetailSheet(
        saint: saint,
        dateFormatted: dateFormatted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 40,
            offset: Offset(0, -10),
          )
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Byzantine Ornament
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: EverforestColors.yellow.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              EverforestColors.yellow.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('☩',
                              style: TextStyle(
                                  color: EverforestColors.yellow,
                                  fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            dateFormatted,
                            style: const TextStyle(
                              color: EverforestColors.yellow,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('☩',
                              style: TextStyle(
                                  color: EverforestColors.yellow,
                                  fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Saint Icon & Title Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              EverforestColors.yellow.withValues(alpha: 0.15),
                          border: Border.all(
                            color: EverforestColors.yellow
                                .withValues(alpha: 0.4),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: EverforestColors.yellow
                                  .withValues(alpha: 0.1),
                              blurRadius: 15,
                            )
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.church_rounded,
                              size: 36, color: EverforestColors.yellow),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              saint.name,
                              style: const TextStyle(
                                color: EverforestColors.fg,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            if (saint.title.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                saint.title,
                                style: const TextStyle(
                                  color: EverforestColors.green,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Full Synaxarion Biography
                  const Text(
                    'ΒΙΟΣ & ΣΥΝΑΞΑΡΙΟΝ',
                    style: TextStyle(
                      color: EverforestColors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: EverforestColors.bg1,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Text(
                      saint.fullLife.isNotEmpty
                          ? saint.fullLife
                          : saint.shortLife,
                      style: const TextStyle(
                        color: EverforestColors.fg,
                        fontSize: 14.5,
                        height: 1.65,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Apolytikion Box
                  if (saint.apolytikion.isNotEmpty) ...[
                    const Text(
                      'ΑΠΟΛΥΤΙΚΙΟΝ',
                      style: TextStyle(
                        color: EverforestColors.yellow,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: EverforestColors.bg1,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: EverforestColors.yellow
                              .withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            saint.apolytikion,
                            style: const TextStyle(
                              color: EverforestColors.fg,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Kontakion Box
                  if (saint.kontakion.isNotEmpty) ...[
                    const Text(
                      'ΚΟΝΤΑΚΙΟΝ',
                      style: TextStyle(
                        color: EverforestColors.purple,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: EverforestColors.bg1,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: EverforestColors.purple
                              .withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        saint.kontakion,
                        style: const TextStyle(
                          color: EverforestColors.fg,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Megalynarion Box
                  if (saint.megalynarion.isNotEmpty) ...[
                    const Text(
                      'ΜΕΓΑΛΥΝΑΡΙΟΝ',
                      style: TextStyle(
                        color: EverforestColors.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: EverforestColors.bg1,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              EverforestColors.blue.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        saint.megalynarion,
                        style: const TextStyle(
                          color: EverforestColors.fg,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
