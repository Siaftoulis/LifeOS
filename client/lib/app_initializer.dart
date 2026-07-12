import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drift/native.dart';
import 'database/database.dart';
import 'database/preferences_service.dart';
import 'auth_service.dart';
import 'api_client.dart';
import 'feature_registry.dart';
import 'core/local_discovery_service.dart';
import 'core/p2p_transfer_service.dart';

class AppInitializer {
  static Future<void> initialize(Stopwatch s) async {
    Future.microtask(() async {
      final discoveryStart = s.elapsedMilliseconds;
      LocalDiscoveryService.instance.start();
      await P2PTransferService.instance.startServer();
      debugPrint('LifeOSInit: P2P & mDNS started at ${s.elapsedMilliseconds}ms (took ${s.elapsedMilliseconds - discoveryStart}ms)');
    });

    final dbFolder = await getApplicationDocumentsDirectory();
    debugPrint('LifeOSInit: getApplicationDocumentsDirectory resolved at ${s.elapsedMilliseconds}ms');

    final prefsStart = s.elapsedMilliseconds;
    await PreferencesService.load(dir: dbFolder);
    debugPrint('LifeOSInit: PreferencesService.load() took ${s.elapsedMilliseconds - prefsStart}ms');
    
    if (PreferencesService.rememberMe.value && PreferencesService.authToken.value.isNotEmpty) {
      final authStart = s.elapsedMilliseconds;
      AuthService.instance.restoreSession(
        PreferencesService.authToken.value,
        PreferencesService.userProfileJson.value,
      );
      debugPrint('LifeOSInit: restoreSession took ${s.elapsedMilliseconds - authStart}ms');
    }

    final dbInitStart = s.elapsedMilliseconds;
    final dbFile = File('${dbFolder.path}/lifeos.sqlite');
    final db = AppDatabase(NativeDatabase(dbFile));
    debugPrint('LifeOSInit: AppDatabase creation took ${s.elapsedMilliseconds - dbInitStart}ms');

    final registryStart = s.elapsedMilliseconds;
    final base = PreferencesService.cachedBaseUrl.value;
    final daemon = PreferencesService.cachedDaemonUrl.value;
    final api = ApiClient(baseUrl: base, daemonUrl: daemon);
    FeatureRegistry.buildRegistry(db, api);
    debugPrint('LifeOSInit: FeatureRegistry.buildRegistry took ${s.elapsedMilliseconds - registryStart}ms');

    _startBackgroundDiscovery();

    debugPrint('LifeOSInit: initialization complete at ${s.elapsedMilliseconds}ms');
  }

  static void _startBackgroundDiscovery() {
    Future.microtask(() async {
      try {
        final resolved = await Future.wait([
          ApiClient.discoverBaseUrl(),
          ApiClient.discoverDaemonUrl(),
        ]).timeout(const Duration(seconds: 4));
        
        final base = resolved[0];
        final daemon = resolved[1];
        ApiClient.instance.updateUrls(base, daemon);
        await PreferencesService.setCachedUrls(base, daemon);
      } catch (e) {
        debugPrint('Background URL discovery failed: $e');
      }
    });
  }
}
