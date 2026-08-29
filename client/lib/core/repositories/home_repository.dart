import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../api_client.dart';
import '../telemetry/telemetry_reporter.dart';
import 'base_daemon_repository.dart';
import 'models/domain_models.dart';

/// Smart home devices (`GET /api/v1/home/devices`), toggled via POST.
class HomeRepository extends DaemonRepository {
  static final HomeRepository instance = HomeRepository._();

  HomeRepository._();

  final ValueNotifier<List<SmartDevice>> devices = ValueNotifier(const []);

  @override
  Future<void> load() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/home/devices');
      if (res is List) {
        devices.value = res
            .whereType<Map>()
            .map((m) => SmartDevice.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (_) {}
  }

  Future<void> toggle(String deviceId) async {
    try {
      await ApiClient.instance
          .postDaemon('/api/v1/home/devices/toggle', {'device_id': deviceId});
      await load();
      TelemetryReporter.instance.track('home', 'device_toggled', {'device_id': deviceId});
    } catch (_) {}
  }
}
