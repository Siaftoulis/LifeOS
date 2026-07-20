import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../api_client.dart';

class KnowledgeBaseDashboard extends StatefulWidget {
  const KnowledgeBaseDashboard({super.key});

  @override
  State<KnowledgeBaseDashboard> createState() => _KnowledgeBaseDashboardState();
}

class _KnowledgeBaseDashboardState extends State<KnowledgeBaseDashboard> {
  List<dynamic> _categories = [];
  List<dynamic> _articles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final categoriesRes = await ApiClient.instance.getDaemon('/api/v1/knowledge/categories');
      final articlesRes = await ApiClient.instance.getDaemon('/api/v1/knowledge/articles');

      if (mounted) {
        setState(() {
          _categories = categoriesRes as List<dynamic>;
          _articles = articlesRes as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!e.toString().contains('Connection refused')) {
        debugPrint('Error fetching knowledge base data: $e');
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'lightbulb_outline':
        return Icons.lightbulb_outline;
      case 'computer':
        return Icons.computer;
      case 'science_outlined':
        return Icons.science_outlined;
      case 'account_balance':
        return Icons.account_balance;
      default:
        return Icons.folder;
    }
  }

  Color _getColor(String colorString) {
    if (colorString.startsWith('0x')) {
      try {
        return Color(int.parse(colorString));
      } catch (e) {
        return EverforestColors.grey;
      }
    }
    return EverforestColors.grey;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: EverforestColors.bg0,
        child: const Center(child: CircularProgressIndicator(color: EverforestColors.green)),
      );
    }

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
                color: EverforestColors.fg.withValues(alpha: 0.7),
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
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        style: const TextStyle(color: EverforestColors.fg),
        decoration: InputDecoration(
          hintText: 'Search articles, topics, or tags...',
          hintStyle: TextStyle(color: EverforestColors.grey.withValues(alpha: 0.8)),
          prefixIcon: const Icon(Icons.search, color: EverforestColors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    if (_categories.isEmpty) {
      return const Text('No categories found.', style: TextStyle(color: EverforestColors.grey));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final iconData = _getIconData(cat['icon'] ?? '');
          final color = _getColor(cat['color'] ?? '');
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
                Icon(iconData, color: color),
                const SizedBox(width: 12),
                Text(
                  cat['title'] ?? 'Unknown',
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
    if (_articles.isEmpty) {
      return const Text('No recent articles.', style: TextStyle(color: EverforestColors.grey));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _articles.length,
      itemBuilder: (context, index) {
        final article = _articles[index];
        final color = _getColor(article['color'] ?? '');
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: EverforestColors.bg1,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: EverforestColors.bg2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      article['category'] ?? 'Uncategorized',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    article['date'] ?? '',
                    style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                article['title'] ?? 'Untitled',
                style: const TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                article['excerpt'] ?? '',
                style: TextStyle(
                  color: EverforestColors.fg.withValues(alpha: 0.7),
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
