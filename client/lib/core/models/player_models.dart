class PlayerStats {
  final double age;
  final int xp;
  final double willpower;
  final int biologicalCap;
  final int rawLevel;
  final int effectiveLevel;
  final int nextLevelXp;
  final int atrophyBufferDays;

  PlayerStats({
    required this.age,
    required this.xp,
    required this.willpower,
    required this.biologicalCap,
    required this.rawLevel,
    required this.effectiveLevel,
    required this.nextLevelXp,
    required this.atrophyBufferDays,
  });

  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      age: (json['age'] ?? 0).toDouble(),
      xp: json['xp'] ?? 0,
      willpower: (json['willpower'] ?? 0).toDouble(),
      biologicalCap: json['biological_cap'] ?? 0,
      rawLevel: json['raw_level'] ?? 0,
      effectiveLevel: json['effective_level'] ?? 0,
      nextLevelXp: json['next_level_xp'] ?? 0,
      atrophyBufferDays: json['atrophy_buffer_days'] ?? 0,
    );
  }
}

class IllnessState {
  final String id;
  final String type; // "stasis", "injury", "illness"
  final double baseDays;
  final double actualDays;
  final int startTime;
  final bool isActive;

  IllnessState({
    required this.id,
    required this.type,
    required this.baseDays,
    required this.actualDays,
    required this.startTime,
    required this.isActive,
  });

  factory IllnessState.fromJson(Map<String, dynamic> json) {
    // If there's a "status" field, it might be the healthy state representation
    if (json.containsKey('status') && json['status'] == 'healthy') {
      return IllnessState(
        id: '',
        type: 'healthy',
        baseDays: 0,
        actualDays: 0,
        startTime: 0,
        isActive: false,
      );
    }
    return IllnessState(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      baseDays: (json['base_days'] ?? 0).toDouble(),
      actualDays: (json['actual_days'] ?? 0).toDouble(),
      startTime: json['start_time'] ?? 0,
      isActive: json['is_active'] ?? false,
    );
  }
}

class TaskReward {
  final int pointsAdded;
  final int xpAdded;
  final int attributeXpAdded;
  final String attributeName;

  TaskReward({
    required this.pointsAdded,
    required this.xpAdded,
    required this.attributeXpAdded,
    required this.attributeName,
  });

  factory TaskReward.fromJson(Map<String, dynamic> json) {
    return TaskReward(
      pointsAdded: json['PointsAdded'] ?? 0,
      xpAdded: json['XPAdded'] ?? 0,
      attributeXpAdded: json['AttributeXPAdded'] ?? 0,
      attributeName: json['AttributeName'] ?? '',
    );
  }
}
