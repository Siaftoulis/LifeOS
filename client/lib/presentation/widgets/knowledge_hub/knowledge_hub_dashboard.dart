import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../book_library/book_library_dashboard.dart';
import '../flashcards/flashcards_dashboard.dart';
import '../knowledge_base/knowledge_base_dashboard.dart';
import '../project_infinity/project_infinity_dashboard.dart';
import '../zen_workspace.dart';

class KnowledgeHubDashboard extends StatelessWidget {
  const KnowledgeHubDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: EverforestColors.bg0,
        appBar: AppBar(
          backgroundColor: EverforestColors.bg1,
          title: const Text('Knowledge Hub', style: TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold)),
          elevation: 0,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Knowledge Base'),
              Tab(text: 'Book Library'),
              Tab(text: 'Flashcards'),
              Tab(text: 'Project Infinity'),
              Tab(text: 'Obsidian Zen'),
            ],
            labelColor: EverforestColors.green,
            unselectedLabelColor: EverforestColors.grey,
            indicatorColor: EverforestColors.green,
          ),
        ),
        body: const TabBarView(
          physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          children: [
            KnowledgeBaseDashboard(),
            BookLibraryDashboard(),
            FlashcardsDashboard(),
            ProjectInfinityDashboard(),
            ZenWorkspace(),
          ],
        ),
      ),
    );
  }
}
