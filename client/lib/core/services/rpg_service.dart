import '../models/player_models.dart';
import '../../api_client.dart';

class RpgService {
  Future<PlayerStats?> getPlayerStats() async {
    try {
      final data = await ApiClient.instance.getDaemon('/api/v1/player/stats');
      return PlayerStats.fromJson(data);
    } catch (e) {
      print('Error fetching player stats: $e');
      return PlayerStats.fromJson({
        'age': 25.0,
        'xp': 1250,
        'willpower': 100.0,
        'biological_cap': 30,
        'raw_level': 5,
        'effective_level': 5,
        'next_level_xp': 2000,
        'atrophy_buffer_days': 3,
        'attributes': {'stamina': 10, 'intelligence': 15, 'focus': 12, 'charisma': 8, 'willpower': 14}
      });
    }
  }

  Future<IllnessState?> getCurrentIllness() async {
    try {
      final data = await ApiClient.instance.getDaemon('/api/v1/illness/current');
      return IllnessState.fromJson(data);
    } catch (e) {
      print('Error fetching current illness: $e');
      return IllnessState.fromJson({
        'type': 'healthy',
        'is_active': false,
        'base_days': 0.0,
        'actual_days': 0.0,
        'start_time': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      });
    }
  }

  Future<IllnessState?> applyIllness(String type, double baseDays, double willpower) async {
    try {
      final data = await ApiClient.instance.postDaemon('/api/v1/illness/apply', {
        'type': type,
        'base_days': baseDays,
        'willpower': willpower,
      });
      return IllnessState.fromJson(data);
    } catch (e) {
      print('Error applying illness: $e');
    }
    return null;
  }

  Future<bool> recoverIllness() async {
    try {
      await ApiClient.instance.postDaemon('/api/v1/illness/recover', {});
      return true;
    } catch (e) {
      print('Error recovering illness: $e');
    }
    return false;
  }

  Future<TaskReward?> completeTask(String taskId, String attribute, int baseXP, int basePoints, bool isSick) async {
    try {
      final data = await ApiClient.instance.postDaemon('/api/v1/player/task/complete', {
        'task_id': taskId,
        'attribute': attribute,
        'base_xp': baseXP,
        'base_points': basePoints,
        'is_sick': isSick,
      });
      if (data.containsKey('reward')) {
        return TaskReward.fromJson(data['reward']);
      }
    } catch (e) {
      print('Error completing task: $e');
    }
    return null;
  }
}
