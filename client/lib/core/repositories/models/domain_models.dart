/// Points balance (`GET /api/v1/points/balance`): points + stars.
class PointsBalance {
  const PointsBalance({required this.points, required this.stars});

  factory PointsBalance.fromJson(Map<String, dynamic> json) => PointsBalance(
        points: (json['points'] as num?)?.toInt() ?? 0,
        stars: (json['stars'] as num?)?.toInt() ?? 0,
      );

  final int points;
  final int stars;
}

class SmartDevice {
  const SmartDevice({
    required this.deviceId,
    required this.name,
    required this.type,
    required this.state,
  });

  factory SmartDevice.fromJson(Map<String, dynamic> json) => SmartDevice(
        deviceId: json['device_id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        state: json['state']?.toString() ?? 'OFF',
      );

  final String deviceId;
  final String name;
  final String type;
  final String state;
}

class FlashcardDeck {
  const FlashcardDeck({
    required this.id,
    required this.name,
    required this.newCards,
    required this.dueCards,
  });

  factory FlashcardDeck.fromJson(Map<String, dynamic> json) => FlashcardDeck(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Unknown Deck',
        newCards: (json['new_cards'] as num?)?.toInt() ?? 0,
        dueCards: (json['due_cards'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String name;
  final int newCards;
  final int dueCards;
}
