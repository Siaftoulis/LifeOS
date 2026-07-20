import 'package:flutter/foundation.dart';
import '../../api_client.dart';

class GeneralEngineEntity {
  final String id;
  final String type;
  final String creatorId;
  final Map<String, dynamic> payload;
  final List<String> sharedWith;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  GeneralEngineEntity({
    required this.id,
    required this.type,
    required this.creatorId,
    required this.payload,
    required this.sharedWith,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GeneralEngineEntity.fromJson(Map<String, dynamic> json) {
    List<String> shared = [];
    if (json['shared_with'] != null && json['shared_with'] is List) {
      shared = (json['shared_with'] as List).map((x) => x.toString()).toList();
    }
    Map<String, dynamic> payloadMap = {};
    if (json['payload'] != null && json['payload'] is Map) {
      payloadMap = Map<String, dynamic>.from(json['payload']);
    }

    return GeneralEngineEntity(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      creatorId: json['creator_id']?.toString() ?? '',
      payload: payloadMap,
      sharedWith: shared,
      assignedTo: json['assigned_to']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'creator_id': creatorId,
      'payload': payload,
      'shared_with': sharedWith,
      'assigned_to': assignedTo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class GeneralEngineClient {
  static const String _endpoint = '/api/v1/engine/entities';

  /// Fetches all entities accessible to the current authenticated user
  static Future<List<GeneralEngineEntity>> getEntities() async {
    try {
      final response = await ApiClient.instance.getDaemon(_endpoint);
      if (response != null && response is List) {
        final List<GeneralEngineEntity> list = [];
        for (var item in response) {
          if (item is Map) {
            try {
              final map = Map<String, dynamic>.from(item);
              list.add(GeneralEngineEntity.fromJson(map));
            } catch (err) {
              debugPrint('Failed to parse entity item: $err');
            }
          }
        }
        return list;
      }
      return [];
    } catch (_) {
      // Host daemon is offline or discovering active route; silently fallback to offline cache
      return [];
    }
  }

  /// Pushes a new or updated entity to the General Engine
  static Future<GeneralEngineEntity?> saveEntity(GeneralEngineEntity entity) async {
    try {
      final response = await ApiClient.instance.postDaemon(_endpoint, entity.toJson());
      if (response != null && response is Map) {
        return GeneralEngineEntity.fromJson(Map<String, dynamic>.from(response));
      }
      return null;
    } catch (e) {
      debugPrint('GeneralEngineClient saveEntity error: $e');
      return null;
    }
  }
}
