import 'package:flutter/material.dart';
import 'core/update/ota_update_service.dart';
import 'theme/everforest_colors.dart';

class UpdateManager extends StatelessWidget {
  final dynamic api;
  const UpdateManager({super.key, this.api});

  static Future<void> checkForUpdates(BuildContext ctx, [dynamic api]) async {
    await OtaUpdateService.instance.checkSilentUpdate();
  }

  Future<void> downloadAndInstallAPK() async {
    await OtaUpdateService.instance.checkSilentUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final ota = OtaUpdateService.instance;
    return Container(
      margin: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () => ota.checkSilentUpdate(),
        icon: const Icon(Icons.system_update_rounded, color: EverforestColors.bg0),
        label: const Text(
          "Check & Install OTA Update",
          style: TextStyle(color: EverforestColors.bg0, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: EverforestColors.green,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
