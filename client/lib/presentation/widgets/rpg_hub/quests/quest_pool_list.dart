import 'package:flutter/material.dart';
import '../../../../theme/everforest_colors.dart';
import '../../../../api_client.dart';

class QuestPoolList extends StatefulWidget {
  final VoidCallback? onQuestActivated;
  final bool isAdmin;
  const QuestPoolList({super.key, this.onQuestActivated, this.isAdmin = false});

  @override
  State<QuestPoolList> createState() => _QuestPoolListState();
}

class _QuestPoolListState extends State<QuestPoolList> {
  List<dynamic> _quests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPoolQuests();
  }

  Future<void> _fetchPoolQuests() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/rpg/quests');
      if (mounted) {
        setState(() {
          final allQuests = res as List<dynamic>;
          _quests = allQuests.where((q) => q['status'] == 'POOL').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching pool quests: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: EverforestColors.green),
      );
    }

    if (_quests.isEmpty) {
      return const Center(
        child: Text(
          "No quests available in the pool.",
          style: TextStyle(color: EverforestColors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('QUEST POOL', style: TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 24),
        ..._quests.map((q) {
          return _buildPoolItem(
            q,
            () async {
              try {
                setState(() => _isLoading = true);
                await ApiClient.instance.postDaemon('/api/v1/rpg/quests/activate', {'quest_id': q['id']});
                await _fetchPoolQuests();
                if (widget.onQuestActivated != null) {
                  widget.onQuestActivated!();
                }
              } catch (e) {
                debugPrint('Failed to activate quest: $e');
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            }
          );
        }),
      ],
    );
  }

  Widget _buildPoolItem(dynamic quest, VoidCallback onActivate) {
    final title = quest['title'] ?? 'Unknown';
    final reward = quest['xp_reward'] ?? 0;
    final assignedUsers = quest['assigned_users'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: EverforestColors.bg1,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.assignment, color: EverforestColors.blue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: EverforestColors.fg, fontSize: 15, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: EverforestColors.yellow, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$reward',
                      style: const TextStyle(color: EverforestColors.yellow, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    if (assignedUsers.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.people, color: EverforestColors.grey, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          assignedUsers.split(',').map((e) => e.split(':').first).join(', '),
                          style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (widget.isAdmin) ...[
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => _editQuest(quest),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.edit, color: EverforestColors.grey, size: 18),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => _deleteQuest(quest['id']),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.delete_outline, color: EverforestColors.red, size: 18),
              ),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: EverforestColors.green),
            onPressed: onActivate,
            tooltip: 'Add to Today',
          )
        ],
      ),
    );
  }

  void _deleteQuest(String questId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EverforestColors.bg1,
        title: const Text('Delete Quest', style: TextStyle(color: EverforestColors.fg)),
        content: const Text('Are you sure you want to delete this quest?', style: TextStyle(color: EverforestColors.fg)),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: EverforestColors.grey)),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: EverforestColors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _isLoading = true);
        await ApiClient.instance.postDaemon('/api/v1/rpg/quests/delete', {'quest_id': questId});
        await _fetchPoolQuests();
      } catch (e) {
        debugPrint('Failed to delete quest: $e');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _editQuest(dynamic quest) async {
    final titleController = TextEditingController(text: quest['title']);
    final descController = TextEditingController(text: quest['description']);
    final xpController = TextEditingController(text: quest['xp_reward'].toString());
    final assignedUsersController = TextEditingController(text: quest['assigned_users'] ?? '');

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EverforestColors.bg1,
        title: const Text('Edit Quest', style: TextStyle(color: EverforestColors.fg)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: EverforestColors.fg),
                decoration: const InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: EverforestColors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descController,
                style: const TextStyle(color: EverforestColors.fg),
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: EverforestColors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: xpController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: EverforestColors.fg),
                decoration: const InputDecoration(
                  labelText: 'Star Reward',
                  labelStyle: TextStyle(color: EverforestColors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: assignedUsersController,
                style: const TextStyle(color: EverforestColors.fg),
                decoration: const InputDecoration(
                  labelText: 'Assigned Users (e.g. panospds:50,user2:50)',
                  labelStyle: TextStyle(color: EverforestColors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: EverforestColors.grey)),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Save', style: TextStyle(color: EverforestColors.green)),
            onPressed: () async {
              try {
                final xp = int.tryParse(xpController.text) ?? 50;
                await ApiClient.instance.postDaemon('/api/v1/rpg/quests/update', {
                  'quest_id': quest['id'],
                  'title': titleController.text,
                  'description': descController.text,
                  'xp_reward': xp,
                  'assigned_users': assignedUsersController.text,
                  'progress': quest['progress'] ?? 0,
                });
                if (context.mounted) Navigator.pop(context, true);
              } catch (e) {
                debugPrint('Failed to update quest: $e');
              }
            },
          ),
        ],
      ),
    );

    if (updated == true) {
      _fetchPoolQuests();
    }
  }
}
