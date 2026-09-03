import 'dart:async';
import 'package:flutter/foundation.dart';
import 'database/database.dart';
import 'database/preferences_service.dart';
import 'database/db_executor.dart';
import 'platform_dirs.dart';
import 'api_client.dart';
import 'feature_registry.dart';
import 'core/event_hub.dart';
import 'core/points_live_feedback.dart';
import 'core/local_discovery_service.dart';
import 'core/p2p_transfer_service.dart';
import 'core/update/ota_update_service.dart';
import 'core/repositories/built_in_prayers.dart';

class AppInitializer {
  static Future<void> initialize(Stopwatch s) async {
    if (!kIsWeb) {
      Future.microtask(() async {
        final discoveryStart = s.elapsedMilliseconds;
        LocalDiscoveryService.instance.start();
        await P2PTransferService.instance.startServer();
        debugPrint('LifeOSInit: P2P & mDNS started at ${s.elapsedMilliseconds}ms (took ${s.elapsedMilliseconds - discoveryStart}ms)');
      });
    }

    // ponytail: web is served by the daemon itself → same-origin cloud URLs
    final resolved = kIsWeb
        ? [Uri.base.origin, Uri.base.origin]
        : await Future.wait([ApiClient.discoverBaseUrl(), ApiClient.discoverDaemonUrl()]);
    final base = resolved[0];
    final daemon = resolved[1];
    debugPrint('LifeOSInit: base=$base daemon=$daemon');

    final prefsStart = s.elapsedMilliseconds;
    final dir = kIsWeb ? null : await prefsDir();
    await PreferencesService.load(dir: dir);    debugPrint('LifeOSInit: PreferencesService.load() took ${s.elapsedMilliseconds - prefsStart}ms');
    PreferencesService.cachedBaseUrl.value = base;
    PreferencesService.cachedDaemonUrl.value = daemon;

    final dbInitStart = s.elapsedMilliseconds;
    final db = AppDatabase(await openDbExecutor());
    debugPrint('LifeOSInit: AppDatabase creation took ${s.elapsedMilliseconds - dbInitStart}ms');

    final registryStart = s.elapsedMilliseconds;
    final api = ApiClient(baseUrl: base, daemonUrl: daemon);
    FeatureRegistry.buildRegistry(db, api);
    debugPrint('LifeOSInit: FeatureRegistry.buildRegistry took ${s.elapsedMilliseconds - registryStart}ms');

    // Push channel: live ecosystem events (points, movies, books, ...)
    EventHub.instance.connect();
    PointsLiveFeedback.instance.start();

    _startBackgroundDiscovery();
    BuiltInPrayers.ensureLoaded();
    if (!kIsWeb) {
      OtaUpdateService.instance.initialize();
    }

    debugPrint('LifeOSInit: initialization complete at ${s.elapsedMilliseconds}ms');
  }

  static void _startBackgroundDiscovery() {
    if (kIsWeb) return;
    Future.microtask(() async {
      try {
        final resolved = await Future.wait([
          ApiClient.discoverBaseUrl(),
          ApiClient.discoverDaemonUrl(),
        ]);
        final base = resolved[0];
        final daemon = resolved[1];

        if (base != PreferencesService.cachedBaseUrl.value) {
          PreferencesService.cachedBaseUrl.value = base;
        }
        if (daemon != PreferencesService.cachedDaemonUrl.value) {
          PreferencesService.cachedDaemonUrl.value = daemon;
        }
        ApiClient.instance.updateUrls(base, daemon);
      } catch (e) {
        debugPrint('LifeOSInit: Background discovery failed: $e');
      }
    });
  }
}
