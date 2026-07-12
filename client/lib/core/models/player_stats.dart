class PlayerStats {
  final double age;
  final int xp;
  final double willpower;
  final int biologicalCap;
  final int rawLevel;
  final int effectiveLevel;
  final int nextLevelXp;
  final int atrophyBufferDays;
  final Map<String, int> attributes;

  PlayerStats({
    required this.age,
    required this.xp,
    required this.willpower,
    required this.biologicalCap,
    required this.rawLevel,
    required this.effectiveLevel,
    required this.nextLevelXp,
    required this.atrophyBufferDays,
    required this.attributes,
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
      attributes: Map<String, int>.from(json['attributes'] ?? {}),
    );
  }
}
