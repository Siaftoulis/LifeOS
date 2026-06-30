import 'package:flutter/material.dart';
import '../../theme/everforest_colors.dart';

class CloudView extends StatelessWidget {
  const CloudView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: EverforestColors.bg0,
        appBar: AppBar(
          backgroundColor: EverforestColors.bg0,
          elevation: 0,
          title: const Text('Cloud Sync', style: TextStyle(color: EverforestColors.fg)),
          bottom: const TabBar(
            indicatorColor: EverforestColors.green,
            labelColor: EverforestColors.green,
            unselectedLabelColor: EverforestColors.grey,
            tabs: [
              Tab(text: 'Timeline'),
              Tab(text: 'Folders'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.sync, color: EverforestColors.green),
              onPressed: () {
                // Trigger manual sync
              },
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            Center(child: Text('Timeline View (All users)', style: TextStyle(color: EverforestColors.fg))),
            Center(child: Text('Folder View (By User/Device)', style: TextStyle(color: EverforestColors.fg))),
          ],
        ),
      ),
    );
  }
}
