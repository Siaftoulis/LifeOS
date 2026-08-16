import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' show Variable;
import 'api_client.dart';
import 'auth_service.dart';
import 'database/database.dart';

import 'core/general_engine/engine_repository.dart';

class NotificationPollService {
  Timer? _timer;
  VoidCallback? _engineListener;

  void start() {
    _timer?.cancel();
    
    // Listen to EngineRepository notifications reactively
    _engineListener = () async {
      final notifs = EngineRepository.instance.notifications;
      final dao = AppDatabase.instance.homeScreenDao;
      for (final n in notifs) {
        final id = n.id;
        final title = n.payload['title'] as String? ?? 'Multiplayer Notification';
        final message = n.payload['message'] as String? ?? '';
        final category = 'MULTIPLAYER';
        final createdAt = n.createdAt.millisecondsSinceEpoch ~/ 1000;

        final existing = await AppDatabase.instance.customSelect(
          'SELECT 1 FROM local_notifications WHERE id = ?',
          variables: [Variable.withString(id)],
        ).getSingleOrNull();

        if (existing == null) {
          await dao.insertNotification(LocalNotificationsCompanion.insert(
            id: id,
            title: title,
            message: message,
            category: category,
            createdAt: createdAt,
          ));
        }
      }
    };

    EngineRepository.instance.allEntities.addListener(_engineListener!);

    _timer = Timer.periodic(const Duration(seconds: 4), (_) async {
      try {
        if (!AuthService.instance.isAuthenticated) return;
        final List<dynamic> list = await ApiClient.instance.postDaemon('/api/v1/notifications', {});
        final dao = AppDatabase.instance.homeScreenDao;
        for (final item in list) {
          final String id = item['id'] ?? '';
          final String title = item['title'] ?? '';
          final String message = item['message'] ?? '';
          final String category = item['category'] ?? 'SYSTEM';
          final int createdAt = item['created_at'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
          
          final existing = await AppDatabase.instance.customSelect(
            'SELECT 1 FROM local_notifications WHERE id = ?',
            variables: [Variable.withString(id)],
          ).getSingleOrNull();

          if (existing == null) {
            await dao.insertNotification(LocalNotificationsCompanion.insert(
              id: id,
              title: title,
              message: message,
              category: category,
              createdAt: createdAt,
            ));
          }
        }
      } catch (e) {
        // Silently ignore expected network / auth retry exceptions during startup
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    if (_engineListener != null) {
      EngineRepository.instance.allEntities.removeListener(_engineListener!);
      _engineListener = null;
    }
  }
}
