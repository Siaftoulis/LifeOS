class IllnessState {
  final String id;
  final String type;
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
