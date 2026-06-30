import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/player_models.dart';

class RpgService {
  // Use 10.0.2.2 for Android emulator pointing to host localhost, or localhost if testing native windows
  // Or the host-daemon IP
  final String baseUrl = 'http://127.0.0.1:50051/api/v1';

  Future<PlayerStats?> getPlayerStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/player/stats'));
      if (response.statusCode == 200) {
        return PlayerStats.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Error fetching player stats: $e');
    }
    return null;
  }

  Future<IllnessState?> getCurrentIllness() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/illness/current'));
      if (response.statusCode == 200) {
        return IllnessState.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Error fetching current illness: $e');
    }
    return null;
  }

  Future<IllnessState?> applyIllness(String type, double baseDays, double willpower) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/illness/apply'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': type,
          'base_days': baseDays,
          'willpower': willpower,
        }),
      );
      if (response.statusCode == 200) {
        return IllnessState.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Error applying illness: $e');
    }
    return null;
  }

  Future<bool> recoverIllness() async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/illness/recover'));
      return response.statusCode == 200;
    } catch (e) {
      print('Error recovering illness: $e');
    }
    return false;
  }

  Future<TaskReward?> completeTask(String taskId, String attribute, int baseXP, int basePoints, bool isSick) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/player/task/complete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'task_id': taskId,
          'attribute': attribute,
          'base_xp': baseXP,
          'base_points': basePoints,
          'is_sick': isSick,
        }),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('reward')) {
          return TaskReward.fromJson(data['reward']);
        }
      }
    } catch (e) {
      print('Error completing task: $e');
    }
    return null;
  }
}
