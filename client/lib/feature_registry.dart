import 'package:flutter/material.dart';
import 'vm_card.dart';
import 'habit_panel.dart';
import 'fast_capture_panel.dart';
import 'update_manager.dart';
import 'api_client.dart';

class FeatureItem {
  final String id, title;
  final IconData icon;
  final Widget view;
  const FeatureItem(this.id, this.title, this.icon, this.view);
}

class FeatureRegistry {
  static List<FeatureItem> buildRegistry(dynamic db, ApiClient api) {
    return [
      FeatureItem('FEAT-001', 'Fast Capture', Icons.flash_on, FastCapturePanel(db: db)),
      FeatureItem('UI-002', 'Habits Matrix', Icons.grid_on, HabitMatrixGrid(habitStream: const Stream.empty(), onUpdate: (_, __) {})),
      FeatureItem('UI-003', 'Hyper-V Control', Icons.computer, VMControlCard(name: 'Dev-Node', initialState: VMState.stopped, apiClient: api)),
      FeatureItem('UPD-002', 'System OTA Update', Icons.system_update, UpdateManager(api: api)),
    ];
  }
}
