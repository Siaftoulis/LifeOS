import 'package:flutter/material.dart';
import '../../../../theme/everforest_colors.dart';
import '../quests/add_quest_dialog.dart';
import '../quests/quest_daily_list.dart';
import '../quests/quest_pool_list.dart';

class FamilyQuestsSection extends StatefulWidget {
  final bool isAdmin;
  const FamilyQuestsSection({super.key, required this.isAdmin});

  @override
  State<FamilyQuestsSection> createState() => _FamilyQuestsSectionState();
}

class _FamilyQuestsSectionState extends State<FamilyQuestsSection> {
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
          isWide
              ? Expanded(child: _buildPoolSection(isWide))
              : _buildPoolSection(isWide),
          if (isWide) ...[
            const SizedBox(width: 32),
            Container(width: 1, color: EverforestColors.bg2),
            const SizedBox(width: 32),
          ] else ...[
            const SizedBox(height: 32),
            Container(height: 1, color: EverforestColors.bg2),
            const SizedBox(height: 32),
          ],
          isWide
              ? Expanded(child: _buildActiveSection(isWide))
              : _buildActiveSection(isWide),
        ],
      ),
    );
  }

  Widget _buildPoolSection(bool isWide) {
    final content = QuestPoolList(
        key: UniqueKey(),
        onQuestActivated: () => setState(() {}),
        isAdmin: widget.isAdmin);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
                child: Text('FAMILY QUEST POOL',
                    style: TextStyle(
                        color: EverforestColors.fg,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5))),
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
        if (isWide)
          Expanded(
              child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(), child: content))
        else
          content,
      ],
    );
  }

  Widget _buildActiveSection(bool isWide) {
    final content = QuestDailyList(key: UniqueKey());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ACTIVE QUESTS',
            style: TextStyle(
                color: EverforestColors.fg,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5)),
        const SizedBox(height: 16),
        if (isWide)
          Expanded(
              child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(), child: content))
        else
          content,
      ],
    );
  }
}
