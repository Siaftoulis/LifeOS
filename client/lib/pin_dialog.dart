import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'theme/everforest_colors.dart';
import 'database/preferences_service.dart';

class PinDialog {
  static void show(BuildContext context, {required ValueChanged<bool> onResult}) {
    String pin = '';
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: EverforestColors.bg1,
              title: const Text('Enter PIN', style: TextStyle(color: EverforestColors.fg)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pin.padRight(4, '•'),
                    style: const TextStyle(color: EverforestColors.fg, fontSize: 32, letterSpacing: 16),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: List.generate(10, (i) {
                      final digit = (i + 1) % 10;
                      return ActionChip(
                        backgroundColor: EverforestColors.bg2,
                        label: Text('$digit', style: const TextStyle(color: EverforestColors.fg, fontSize: 24)),
                        onPressed: () {
                          if (pin.length < 4) {
                            setDialogState(() => pin += '$digit');
                            if (pin.length == 4) {
                              final bytes = utf8.encode(pin);
                              final digest = sha256.convert(bytes);
                              if (digest.toString() == PreferencesService.hashedPin.value) {
                                Navigator.pop(context);
                                onResult(true);
                              } else {
                                setDialogState(() => pin = '');
                              }
                            }
                          }
                        },
                      );
                    }),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}
