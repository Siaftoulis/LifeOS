import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'topic_card_widget.dart';
import 'relationship_graph_widget.dart';

class KnowledgeBaseDashboard extends StatelessWidget {
  const KnowledgeBaseDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          const Expanded(
            flex: 2,
            child: RelationshipGraphWidget(),
          ),
          const SizedBox(height: 24),
          const Text('Topics Directory', style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            flex: 3,
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: const [
                TopicCardWidget(title: 'Calculus I', category: 'SCIENCE', status: 'LEARNING'),
                TopicCardWidget(title: 'Stoicism', category: 'PHILOSOPHY', status: 'COMPLETED'),
                TopicCardWidget(title: 'Docker Internals', category: 'TECH', status: 'BACKLOG'),
                TopicCardWidget(title: 'World War II', category: 'HISTORY', status: 'LEARNING'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.menu_book, color: EverforestColors.aqua, size: 28),
        const SizedBox(width: 12),
        const Text('Knowledge Base', style: TextStyle(color: EverforestColors.fg, fontSize: 24, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.search, color: EverforestColors.grey),
          onPressed: () {},
        ),
      ],
    );
  }
}
