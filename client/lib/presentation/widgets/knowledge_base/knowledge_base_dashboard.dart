import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class KnowledgeBaseDashboard extends StatelessWidget {
  const KnowledgeBaseDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildSearchBar(),
          const SizedBox(height: 32),
          const Text(
            'Categories',
            style: TextStyle(
              color: EverforestColors.fg,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildCategories(),
          const SizedBox(height: 32),
          const Text(
            'Recent Articles',
            style: TextStyle(
              color: EverforestColors.fg,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildRecentArticles(),
        ],
      ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Knowledge Base',
              style: TextStyle(
                color: EverforestColors.fg,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your personal wiki and notes',
              style: TextStyle(
                color: EverforestColors.fg.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: EverforestColors.bg1,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EverforestColors.bg2),
          ),
          child: const Icon(Icons.auto_awesome, color: EverforestColors.yellow, size: 28),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EverforestColors.bg2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        style: const TextStyle(color: EverforestColors.fg),
        decoration: InputDecoration(
          hintText: 'Search articles, topics, or tags...',
          hintStyle: TextStyle(color: EverforestColors.grey.withOpacity(0.8)),
          prefixIcon: const Icon(Icons.search, color: EverforestColors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {'title': 'Philosophy', 'icon': Icons.lightbulb_outline, 'color': EverforestColors.orange},
      {'title': 'Technology', 'icon': Icons.computer, 'color': EverforestColors.blue},
      {'title': 'Science', 'icon': Icons.science_outlined, 'color': EverforestColors.aqua},
      {'title': 'History', 'icon': Icons.account_balance, 'color': EverforestColors.yellow},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          return Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: EverforestColors.bg1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: EverforestColors.bg2),
            ),
            child: Row(
              children: [
                Icon(cat['icon'] as IconData, color: cat['color'] as Color),
                const SizedBox(width: 12),
                Text(
                  cat['title'] as String,
                  style: const TextStyle(
                    color: EverforestColors.fg,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentArticles() {
    final articles = [
      {
        'title': 'The Principles of Stoicism',
        'excerpt': 'A deep dive into the core tenets of Stoic philosophy and how they apply to modern life.',
        'date': 'Oct 12, 2023',
        'category': 'Philosophy',
        'color': EverforestColors.orange,
      },
      {
        'title': 'Understanding Docker Internals',
        'excerpt': 'Exploring namespaces, cgroups, and the union filesystem that power Docker containers.',
        'date': 'Oct 10, 2023',
        'category': 'Technology',
        'color': EverforestColors.blue,
      },
      {
        'title': 'Calculus: Limits and Continuity',
        'excerpt': 'Notes on the foundational concepts of differential calculus.',
        'date': 'Oct 08, 2023',
        'category': 'Science',
        'color': EverforestColors.aqua,
      },
      {
        'title': 'The Fall of the Roman Empire',
        'excerpt': 'Key events and structural flaws that led to the decline of ancient Rome.',
        'date': 'Oct 05, 2023',
        'category': 'History',
        'color': EverforestColors.yellow,
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final article = articles[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: EverforestColors.bg1,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EverforestColors.bg2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (article['color'] as Color).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      article['category'] as String,
                      style: TextStyle(
                        color: article['color'] as Color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    article['date'] as String,
                    style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                article['title'] as String,
                style: const TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                article['excerpt'] as String,
                style: TextStyle(
                  color: EverforestColors.fg.withOpacity(0.7),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
