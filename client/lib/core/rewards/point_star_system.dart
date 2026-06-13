import 'package:flutter/foundation.dart';

class PointStarSystem {
  static final PointStarSystem _instance = PointStarSystem._internal();
  factory PointStarSystem() => _instance;
  PointStarSystem._internal();

  int _currentPoints = 0;
  int get currentPoints => _currentPoints;

  void addPoints(int points) {
    _currentPoints += points;
    debugPrint('Added $points Star Points. Total: $_currentPoints');
    // TODO: Persist to database in future iteration.
  }

  void logEditingHour() {
    // Add +5 Star Points for every hour of active note editing
    addPoints(5);
  }
}
