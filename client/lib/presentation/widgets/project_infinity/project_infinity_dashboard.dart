import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class ProjectInfinityDashboard extends StatelessWidget {
  const ProjectInfinityDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          Expanded(child: _buildKanbanBoard()),
        ],
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
              'Project Infinity',
              style: TextStyle(
                color: EverforestColors.fg,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your grandest ambitions',
              style: TextStyle(
                color: EverforestColors.fg.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, color: EverforestColors.bg0),
          label: const Text('New Project', style: TextStyle(color: EverforestColors.bg0, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: EverforestColors.purple,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildKanbanBoard() {
    final columns = [
      {
        'title': 'To Do',
        'color': EverforestColors.blue,
        'tasks': [
          {'title': 'Draft architecture for CRM', 'tag': 'Design', 'tagColor': EverforestColors.orange},
          {'title': 'Research Rust GUI frameworks', 'tag': 'Research', 'tagColor': EverforestColors.aqua},
          {'title': 'Update personal portfolio', 'tag': 'Web', 'tagColor': EverforestColors.yellow},
        ]
      },
      {
        'title': 'In Progress',
        'color': EverforestColors.yellow,
        'tasks': [
          {'title': 'Implement auth service in Go', 'tag': 'Backend', 'tagColor': EverforestColors.green},
          {'title': 'Write Flutter UI components', 'tag': 'Frontend', 'tagColor': EverforestColors.blue},
        ]
      },
      {
        'title': 'Done',
        'color': EverforestColors.green,
        'tasks': [
          {'title': 'Setup PostgreSQL schema', 'tag': 'Database', 'tagColor': EverforestColors.purple},
          {'title': 'Configure CI/CD pipelines', 'tag': 'DevOps', 'tagColor': EverforestColors.red},
        ]
      },
    ];

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: columns.length,
      itemBuilder: (context, index) {
        final column = columns[index];
        final tasks = column['tasks'] as List<Map<String, dynamic>>;

        return Container(
          width: 320,
          margin: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: EverforestColors.bg1,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: EverforestColors.bg2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: EverforestColors.bg2, width: 2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: column['color'] as Color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          column['title'] as String,
                          style: const TextStyle(
                            color: EverforestColors.fg,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: EverforestColors.bg2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${tasks.length}',
                        style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (context, taskIndex) {
                    final task = tasks[taskIndex];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: EverforestColors.bg0,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: EverforestColors.bg2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (task['tagColor'] as Color).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              task['tag'] as String,
                              style: TextStyle(
                                color: task['tagColor'] as Color,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            task['title'] as String,
                            style: const TextStyle(
                              color: EverforestColors.fg,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.sort, color: EverforestColors.grey, size: 16),
                              const SizedBox(width: 16),
                              const Icon(Icons.chat_bubble_outline, color: EverforestColors.grey, size: 16),
                              const Spacer(),
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: EverforestColors.green.withOpacity(0.3),
                                child: const Icon(Icons.person, size: 16, color: EverforestColors.green),
                              )
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
