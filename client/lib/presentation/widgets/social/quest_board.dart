import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import '../../../theme/everforest_colors.dart';
import '../../../database/database.dart';
import '../../../database/chtm_dao.dart';

class QuestBoard extends StatefulWidget {
  const QuestBoard({super.key});

  @override
  State<QuestBoard> createState() => _QuestBoardState();
}

class _QuestBoardState extends State<QuestBoard> {
  late final ChtmDao _dao;
  String _currentUser = 'u-admin-1';

  @override
  void initState() {
    super.initState();
    _dao = ChtmDao(AppDatabase.instance);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      appBar: AppBar(
        title: const Text('Family Quests', style: TextStyle(color: EverforestColors.fg)),
        backgroundColor: EverforestColors.bg1,
        elevation: 0,
      ),
      body: StreamBuilder<List<Quest>>(
        stream: _dao.watchAllQuests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: EverforestColors.green));
          }
          final quests = snapshot.data ?? [];
          if (quests.isEmpty) {
            return _buildEmptyState();
          }
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: quests.map((quest) => _buildQuestCard(quest)).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateQuestDialog,
        backgroundColor: EverforestColors.green,
        child: const Icon(Icons.add, color: EverforestColors.bg0),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: EverforestColors.grey),
          const SizedBox(height: 16),
          Text('No quests yet', style: TextStyle(color: EverforestColors.grey, fontSize: 18)),
          const SizedBox(height: 8),
          Text('Create your first family quest!', style: TextStyle(color: EverforestColors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildQuestCard(Quest quest) {
    final isPending = quest.status == 'PENDING';
    final isOpen = quest.status == 'OPEN';
    final isAccepted = quest.status == 'ACCEPTED';
    final isCompleted = quest.status == 'COMPLETED';
    final isAssignedToCurrentUser = quest.assignedTo == _currentUser;

    Color statusColor;
    switch (quest.status) {
      case 'PENDING':
        statusColor = EverforestColors.orange;
        break;
      case 'OPEN':
        statusColor = EverforestColors.blue;
        break;
      case 'ACCEPTED':
        statusColor = EverforestColors.green;
        break;
      case 'COMPLETED':
        statusColor = EverforestColors.purple;
        break;
      case 'REJECTED':
        statusColor = EverforestColors.red;
        break;
      default:
        statusColor = EverforestColors.grey;
    }

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.only(bottom: 16.0),
      color: EverforestColors.bg1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: EverforestColors.bg2)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    quest.title,
                    style: const TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text('${quest.rewardPoints} XP', style: const TextStyle(color: EverforestColors.bg0, fontSize: 12)),
                  backgroundColor: EverforestColors.yellow,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (quest.description != null && quest.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(quest.description!, style: TextStyle(color: EverforestColors.grey, fontSize: 14)),
              ),
            Row(
              children: [
                _buildStatusChip(quest.status, statusColor),
                const SizedBox(width: 8),
                if (quest.assignedTo != null && quest.assignedTo!.isNotEmpty)
                  _buildAssigneeChip(quest.assignedTo!),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: _buildActionButtons(quest, isPending, isOpen, isAccepted, isCompleted, isAssignedToCurrentUser),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAssigneeChip(String assignee) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: EverforestColors.bg2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 8,
            backgroundColor: EverforestColors.green,
            child: Text(assignee[0].toUpperCase(), style: const TextStyle(color: EverforestColors.bg0, fontSize: 8)),
          ),
          const SizedBox(width: 6),
          Text(assignee, style: const TextStyle(color: EverforestColors.fg, fontSize: 12)),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(Quest quest, bool isPending, bool isOpen, bool isAccepted, bool isCompleted, bool isAssignedToCurrentUser) {
    final buttons = <Widget>[];

    if (isPending) {
      buttons.addAll([
        TextButton(
          onPressed: () => _denyQuest(quest.id),
          child: Text('Deny', style: TextStyle(color: EverforestColors.red)),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => _acceptQuest(quest.id),
          style: ElevatedButton.styleFrom(backgroundColor: EverforestColors.green, foregroundColor: EverforestColors.bg0),
          child: const Text('Accept'),
        ),
      ]);
    } else if (isOpen) {
      buttons.add(
        ElevatedButton(
          onPressed: () => _claimQuest(quest.id),
          style: ElevatedButton.styleFrom(backgroundColor: EverforestColors.blue, foregroundColor: EverforestColors.bg0),
          child: const Text('Claim'),
        ),
      );
    } else if (isAccepted && isAssignedToCurrentUser && !isCompleted) {
      buttons.add(
        ElevatedButton(
          onPressed: () => _completeQuest(quest.id),
          style: ElevatedButton.styleFrom(backgroundColor: EverforestColors.purple, foregroundColor: EverforestColors.bg0),
          child: const Text('Complete'),
        ),
      );
    } else if (isCompleted) {
      buttons.add(
        Chip(
          label: Text('Completed', style: TextStyle(color: EverforestColors.purple, fontSize: 12)),
          backgroundColor: EverforestColors.purple.withValues(alpha: 0.2),
        ),
      );
    }

    return buttons;
  }

  Future<void> _showCreateQuestDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final pointsController = TextEditingController(text: '10');
    String assignee = 'Anyone';

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: EverforestColors.bg1,
          title: Text('Create Quest', style: TextStyle(color: EverforestColors.fg)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: TextStyle(color: EverforestColors.fg),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: EverforestColors.grey),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  style: TextStyle(color: EverforestColors.fg),
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    labelStyle: TextStyle(color: EverforestColors.grey),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pointsController,
                  style: TextStyle(color: EverforestColors.fg),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'XP Reward',
                    labelStyle: TextStyle(color: EverforestColors.grey),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: assignee,
                  dropdownColor: EverforestColors.bg1,
                  style: TextStyle(color: EverforestColors.fg),
                  decoration: InputDecoration(
                    labelText: 'Assignee',
                    labelStyle: TextStyle(color: EverforestColors.grey),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                  ),
                  items: ['Anyone', 'Bob', 'Alice', 'Charlie'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => assignee = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: EverforestColors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                await _dao.insertQuest(QuestsCompanion(
                  id: Value(const Uuid().v4()),
                  title: Value(titleController.text.trim()),
                  description: Value(descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim()),
                  rewardPoints: Value(int.tryParse(pointsController.text) ?? 10),
                  assignedTo: Value(assignee == 'Anyone' ? null : assignee),
                  status: Value('OPEN'),
                  createdBy: Value(_currentUser),
                  createdAt: Value(DateTime.now().millisecondsSinceEpoch),
                  updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
                  isDirty: Value(1),
                ));
                if (mounted) Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: EverforestColors.green, foregroundColor: EverforestColors.bg0),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptQuest(String questId) async {
    await _dao.acceptQuest(questId, _currentUser);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quest accepted!'), backgroundColor: EverforestColors.green),
      );
    }
  }

  Future<void> _denyQuest(String questId) async {
    await _dao.denyQuest(questId, _currentUser);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quest denied'), backgroundColor: EverforestColors.red),
      );
    }
  }

  Future<void> _claimQuest(String questId) async {
    await _dao.claimQuest(questId, _currentUser);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quest claimed!'), backgroundColor: EverforestColors.blue),
      );
    }
  }

  Future<void> _completeQuest(String questId) async {
    await _dao.completeQuest(questId, _currentUser);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quest completed!'), backgroundColor: EverforestColors.purple),
      );
    }
  }
}