import 'package:flutter/material.dart';
import '../../../core/models/player_models.dart';
import '../../../core/services/rpg_service.dart';
import 'rpg_player_card.dart';
import 'illness_status_widget.dart';

class RpgDashboard extends StatefulWidget {
  const RpgDashboard({Key? key}) : super(key: key);

  @override
  _RpgDashboardState createState() => _RpgDashboardState();
}

class _RpgDashboardState extends State<RpgDashboard> {
  final RpgService _rpgService = RpgService();
  
  PlayerStats? _stats;
  IllnessState? _illnessState;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final statsFuture = _rpgService.getPlayerStats();
    final illnessFuture = _rpgService.getCurrentIllness();

    final results = await Future.wait([statsFuture, illnessFuture]);
    
    setState(() {
      _stats = results[0] as PlayerStats?;
      _illnessState = results[1] as IllnessState?;
      _isLoading = false;
    });
  }

  void _showTaskCompletionDialog() {
    final TextEditingController xpController = TextEditingController(text: '50');
    final TextEditingController pointsController = TextEditingController(text: '10');
    String selectedAttr = 'Focus';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Simulate Task Completion"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: xpController,
                decoration: const InputDecoration(labelText: "Base XP"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: pointsController,
                decoration: const InputDecoration(labelText: "Base Points"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedAttr,
                decoration: const InputDecoration(labelText: "Attribute"),
                items: ['Stamina', 'Intelligence', 'Focus', 'Charisma', 'Willpower']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) selectedAttr = val;
                },
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final xp = int.tryParse(xpController.text) ?? 0;
                final pts = int.tryParse(pointsController.text) ?? 0;
                final isSick = _illnessState?.isActive == true && _illnessState?.type == 'mild_illness';
                
                final reward = await _rpgService.completeTask("test_task", selectedAttr, xp, pts, isSick);
                
                if (reward != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Task Complete!\nXP: +${reward.xpAdded}\nPoints: +${reward.pointsAdded}\n${reward.attributeName} XP: +${reward.attributeXpAdded}"
                      ),
                      backgroundColor: Colors.green,
                    )
                  );
                  _loadData();
                }
              },
              child: const Text("Complete Task"),
            )
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("RPG Player Dashboard"),
        backgroundColor: Colors.deepPurple.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: "Complete Task (Test)",
            onPressed: _showTaskCompletionDialog,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  if (_stats != null)
                    RpgPlayerCard(
                      stats: _stats!,
                      activeIllness: _illnessState,
                      onRefresh: _loadData,
                    )
                  else
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text("Could not load player stats. Ensure host-daemon is running."),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  if (_stats != null)
                    IllnessStatusWidget(
                      initialState: _illnessState,
                      willpower: _stats!.willpower,
                      onStateChanged: _loadData,
                    ),
                ],
              ),
            ),
    );
  }
}
