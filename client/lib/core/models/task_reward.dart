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
