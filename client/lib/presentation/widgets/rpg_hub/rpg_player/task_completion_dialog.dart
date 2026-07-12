import 'package:flutter/material.dart';
import '../../../../core/models/player_models.dart';
import '../../../../core/services/rpg_service.dart';

class TaskCompletionDialog {
  static void show(
    BuildContext context,
    IllnessState? illnessState,
    RpgService rpgService,
    VoidCallback onComplete,
  ) {
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
                initialValue: selectedAttr,
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
                final isSick = illnessState?.isActive == true && illnessState?.type == 'mild_illness';
                
                final reward = await rpgService.completeTask("test_task", selectedAttr, xp, pts, isSick);
                
                if (reward != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Task Complete!\nXP: +${reward.xpAdded}\nPoints: +${reward.pointsAdded}\n${reward.attributeName} XP: +${reward.attributeXpAdded}"
                      ),
                      backgroundColor: Colors.green,
                    )
                  );
                  onComplete();
                }
              },
              child: const Text("Complete Task"),
            )
          ],
        );
      }
    );
  }
}
