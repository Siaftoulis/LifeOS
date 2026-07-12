import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' as drift;
import '../../database/database.dart';

class PointStarSystem {
  static final PointStarSystem _instance = PointStarSystem._internal();
  factory PointStarSystem() => _instance;
  PointStarSystem._internal();

  int _currentPoints = 0;
  int get currentPoints => _currentPoints;

  void addPoints(int points) async {
    _currentPoints += points;
    debugPrint('Added $points Star Points. Total: $_currentPoints');
    
    // Persist to database
    try {
      await AppDatabase.instance.into(AppDatabase.instance.pointsLedgers).insert(
        PointsLedgersCompanion(
          id: drift.Value(DateTime.now().millisecondsSinceEpoch.toString()),
          userId: const drift.Value('system'), // Or actual user ID
          event: const drift.Value('Earned Points'),
          points: drift.Value(points),
          timestamp: drift.Value(DateTime.now().millisecondsSinceEpoch),
        )
      );
    } catch (e) {
      debugPrint('Failed to persist points to DB: $e');
    }
  }

  void logEditingHour() {
    // Add +5 Star Points for every hour of active note editing
    addPoints(5);
  }
}
