import 'package:flutter/material.dart';
import '../../../../theme/everforest_colors.dart';
import 'voucher_redeemer_panel.dart';
import 'points_ledger_panel.dart';
import '../../../../api_client.dart';
import '../quests/quest_pool_list.dart';
import '../quests/quest_daily_list.dart';
import '../quests/add_quest_dialog.dart';
import '../../../../auth_service.dart';

class PointStarDashboard extends StatelessWidget {
  const PointStarDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    
    return ValueListenableBuilder<UserProfile?>(
      valueListenable: AuthService.instance.currentUser,
      builder: (context, user, _) {
        final isAdmin = user?.role == 'ADMIN';
        
        return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EverforestColors.bg0,
            EverforestColors.bg1,
          ],
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 16,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'S Y S T E M',
                    style: TextStyle(
                      color: EverforestColors.green,
                      fontSize: 14,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Star System & Family Quests',
                    style: TextStyle(
                      color: EverforestColors.fg,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: EverforestColors.green.withValues(alpha: 0.5), blurRadius: 10)],
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.stars, color: Colors.white),
                    label: const Text('REWARD STORE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EverforestColors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      elevation: 10,
                      shadowColor: EverforestColors.purple.withValues(alpha: 0.8),
                    ),
                    onPressed: () => _showVouchers(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          // BODY
          Expanded(
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Expanded(flex: 1, child: _LeaderboardList()),
                      const SizedBox(width: 32),
                      Expanded(
                        flex: 3, 
                        child: Column(
                          children: [
                            _FamilyGoalWidget(isAdmin: isAdmin),
                            const SizedBox(height: 24),
                            Expanded(child: _FamilyQuestsSection(isAdmin: isAdmin)),
                            const SizedBox(height: 24),
                            SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 420),
                                child: const PointsLedgerPanel(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 300, child: _LeaderboardList()),
                        const SizedBox(height: 24),
                        _FamilyGoalWidget(isAdmin: isAdmin),
                        const SizedBox(height: 24),
                        SizedBox(height: 600, child: _FamilyQuestsSection(isAdmin: isAdmin)),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 420,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: const PointsLedgerPanel(),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
      },
    );
  }

  void _showVouchers(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const VoucherRedeemerPanel(),
    );
  }
}

class _FamilyGoalWidget extends StatefulWidget {
  final bool isAdmin;
  const _FamilyGoalWidget({required this.isAdmin});

  @override
  State<_FamilyGoalWidget> createState() => _FamilyGoalWidgetState();
}

class _FamilyGoalWidgetState extends State<_FamilyGoalWidget> {
  dynamic _mainQuest;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMainQuest();
  }

  Future<void> _fetchMainQuest() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/rpg/quests');
      if (mounted) {
        setState(() {
          final allQuests = res as List<dynamic>;
          _mainQuest = allQuests.firstWhere(
            (q) => q['status'] == 'MAIN',
            orElse: () => null,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching main quest: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: EverforestColors.bg1.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: CircularProgressIndicator(color: EverforestColors.yellow)),
      );
    }

    if (_mainQuest == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: EverforestColors.bg1.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: EverforestColors.yellow.withValues(alpha: 0.3)),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            const Text('No active Main Quest.', style: TextStyle(color: EverforestColors.yellow, fontSize: 16)),
            if (widget.isAdmin)
              ElevatedButton.icon(
                icon: const Icon(Icons.flag, size: 16),
                label: const Text('SET MAIN QUEST'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EverforestColors.yellow,
                  foregroundColor: EverforestColors.bg0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                onPressed: _addMainQuest,
              ),
          ],
        ),
      );
    }

    final title = _mainQuest['title'] ?? 'Main Quest';
    final progress = _mainQuest['progress'] ?? 0;
    final target = _mainQuest['xp_reward'] ?? 100;
    final progressValue = target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EverforestColors.bg1.withValues(alpha: 0.5),
        border: Border.all(color: EverforestColors.yellow.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: EverforestColors.yellow.withValues(alpha: 0.05), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'MAIN QUEST: $title',
                  style: const TextStyle(color: EverforestColors.yellow, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ),
              const SizedBox(width: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$progress / $target Stars',
                    style: const TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (widget.isAdmin) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit, color: EverforestColors.grey, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _editMainQuest,
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 12,
              backgroundColor: EverforestColors.bg0,
              valueColor: AlwaysStoppedAnimation<Color>(EverforestColors.yellow),
            ),
          ),
        ],
      ),
    );
  }

  void _editMainQuest() async {
    final titleController = TextEditingController(text: _mainQuest['title']);
    final targetController = TextEditingController(text: _mainQuest['xp_reward'].toString());
    final progressController = TextEditingController(text: _mainQuest['progress'].toString());

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EverforestColors.bg1,
        title: const Text('Edit Main Quest', style: TextStyle(color: EverforestColors.fg)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: EverforestColors.fg),
              decoration: const InputDecoration(
                labelText: 'Quest Title',
                labelStyle: TextStyle(color: EverforestColors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: progressController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: EverforestColors.fg),
              decoration: const InputDecoration(
                labelText: 'Current Progress (Stars)',
                labelStyle: TextStyle(color: EverforestColors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: EverforestColors.fg),
              decoration: const InputDecoration(
                labelText: 'Target (Stars)',
                labelStyle: TextStyle(color: EverforestColors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
              ),
            ),
          ],
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
                final target = int.tryParse(targetController.text) ?? 200;
                final progress = int.tryParse(progressController.text) ?? 0;
                await ApiClient.instance.postDaemon('/api/v1/rpg/quests/update', {
                  'quest_id': _mainQuest['id'],
                  'title': titleController.text,
                  'description': _mainQuest['description'] ?? 'Main Quest',
                  'xp_reward': target,
                  'assigned_users': _mainQuest['assigned_users'] ?? '',
                  'progress': progress,
                });
                if (context.mounted) Navigator.pop(context, true);
              } catch (e) {
                debugPrint('Failed to update main quest: $e');
              }
            },
          ),
        ],
      ),
    );

    if (updated == true) {
      _fetchMainQuest();
    }
  }

  void _addMainQuest() async {
    final titleController = TextEditingController();
    final targetController = TextEditingController(text: '200');

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EverforestColors.bg1,
        title: const Text('Set Main Quest', style: TextStyle(color: EverforestColors.yellow)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: EverforestColors.fg),
              decoration: const InputDecoration(
                labelText: 'Quest Title (e.g. Family Vacation)',
                labelStyle: TextStyle(color: EverforestColors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.yellow)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: EverforestColors.fg),
              decoration: const InputDecoration(
                labelText: 'Target Stars',
                labelStyle: TextStyle(color: EverforestColors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.yellow)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: EverforestColors.grey)),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: EverforestColors.yellow,
              foregroundColor: EverforestColors.bg0,
            ),
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;
              try {
                final target = int.tryParse(targetController.text) ?? 200;
                await ApiClient.instance.postDaemon('/api/v1/rpg/quests/add-main', {
                  'title': titleController.text.trim(),
                  'description': 'Gather $target stars',
                  'xp_reward': target,
                });
                if (context.mounted) Navigator.pop(context, true);
              } catch (e) {
                debugPrint('Failed to create main quest: $e');
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (created == true) {
      _fetchMainQuest();
    }
  }
}

class _FamilyQuestsSection extends StatefulWidget {
  final bool isAdmin;
  const _FamilyQuestsSection({required this.isAdmin});

  @override
  State<_FamilyQuestsSection> createState() => _FamilyQuestsSectionState();
}

class _FamilyQuestsSectionState extends State<_FamilyQuestsSection> {
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EverforestColors.bg1.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: EverforestColors.bg2),
      ),
      child: Flex(
        direction: isWide ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          isWide ? Expanded(child: _buildPoolSection(isWide)) : _buildPoolSection(isWide),
          if (isWide) ...[
            const SizedBox(width: 32),
            Container(width: 1, color: EverforestColors.bg2),
            const SizedBox(width: 32),
          ] else ...[
            const SizedBox(height: 32),
            Container(height: 1, color: EverforestColors.bg2),
            const SizedBox(height: 32),
          ],
          isWide ? Expanded(child: _buildActiveSection(isWide)) : _buildActiveSection(isWide),
        ],
      ),
    );
  }

  Widget _buildPoolSection(bool isWide) {
    final content = QuestPoolList(key: UniqueKey(), onQuestActivated: () => setState(() {}), isAdmin: widget.isAdmin);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(child: Text('FAMILY QUEST POOL', style: TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5))),
            if (widget.isAdmin)
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('POST'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: EverforestColors.green,
                  elevation: 0,
                  side: const BorderSide(color: EverforestColors.green),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AddQuestDialog(
                      onQuestAdded: () => setState(() {}),
                    ),
                  );
                },
              )
          ],
        ),
        const SizedBox(height: 16),
        if (isWide) Expanded(child: SingleChildScrollView(physics: const BouncingScrollPhysics(), child: content)) else content,
      ],
    );
  }

  Widget _buildActiveSection(bool isWide) {
    final content = QuestDailyList(key: UniqueKey());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ACTIVE QUESTS', style: TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        if (isWide) Expanded(child: SingleChildScrollView(physics: const BouncingScrollPhysics(), child: content)) else content,
      ],
    );
  }
}

class _LeaderboardList extends StatefulWidget {
  const _LeaderboardList();

  @override
  State<_LeaderboardList> createState() => _LeaderboardListState();
}

class _LeaderboardListState extends State<_LeaderboardList> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/points/leaderboard');
      if (mounted) {
        setState(() {
          _users = res as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1.withValues(alpha: 0.5), 
        borderRadius: BorderRadius.circular(8), 
        border: Border.all(color: EverforestColors.blue.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: EverforestColors.blue.withValues(alpha: 0.05), blurRadius: 20)],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('RANKING', style: TextStyle(color: EverforestColors.blue, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: EverforestColors.blue))
                : _users.isEmpty
                    ? const Center(child: Text('No users found', style: TextStyle(color: EverforestColors.grey)))
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          final isFirst = index == 0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isFirst ? EverforestColors.blue.withValues(alpha: 0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: isFirst ? EverforestColors.blue.withValues(alpha: 0.3) : EverforestColors.bg2),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '#${user['rank'] ?? (index + 1)}',
                                  style: TextStyle(
                                    color: isFirst ? EverforestColors.blue : EverforestColors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isFirst ? 20 : 16,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    user['username'] ?? 'Unknown',
                                    style: TextStyle(
                                      color: EverforestColors.fg,
                                      fontWeight: isFirst ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.star, color: EverforestColors.yellow, size: isFirst ? 18 : 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${user['points'] ?? 0}',
                                      style: TextStyle(
                                        color: EverforestColors.fg,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isFirst ? 16 : 14,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      ),
          )
        ],
      ),
    );
  }
}
