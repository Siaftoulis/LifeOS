import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' show Variable;
import 'api_client.dart';
import 'database/database.dart';

class NotificationPollService {
  Timer? _timer;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) async {
      try {
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
        debugPrint('Error polling notifications: $e');
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
