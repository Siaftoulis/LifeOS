import 'package:flutter/material.dart';
import '../../../../core/models/player_models.dart';
import '../../../../core/services/rpg_service.dart';
import '../../../../theme/everforest_colors.dart';
import 'rpg_player_card.dart';
import 'illness_status_widget.dart';
import 'task_completion_dialog.dart';

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
    if (mounted) {
      setState(() {
        _stats = results[0] as PlayerStats?;
        _illnessState = results[1] as IllnessState?;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: EverforestColors.purple))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EverforestColors.purple,
                          foregroundColor: EverforestColors.bg0,
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text("Simulate Task Completion"),
                        onPressed: () => TaskCompletionDialog.show(context, _illnessState, _rpgService, _loadData),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_stats != null)
                    RpgPlayerCard(
                      stats: _stats!,
                      activeIllness: _illnessState,
                      onRefresh: _loadData,
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: EverforestColors.bg1,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: EverforestColors.bg2),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: const Text("Could not load player stats. Ensure host-daemon is running.", style: TextStyle(color: EverforestColors.fg)),
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
