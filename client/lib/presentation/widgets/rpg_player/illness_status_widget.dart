import 'package:flutter/material.dart';
import '../../../core/models/player_models.dart';
import '../../../core/services/rpg_service.dart';

class IllnessStatusWidget extends StatefulWidget {
  final IllnessState? initialState;
  final double willpower;
  final VoidCallback onStateChanged;

  const IllnessStatusWidget({
    Key? key,
    this.initialState,
    required this.willpower,
    required this.onStateChanged,
  }) : super(key: key);

  @override
  _IllnessStatusWidgetState createState() => _IllnessStatusWidgetState();
}

class _IllnessStatusWidgetState extends State<IllnessStatusWidget> {
  late IllnessState? _currentState;
  final RpgService _rpgService = RpgService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentState = widget.initialState;
  }

  @override
  void didUpdateWidget(covariant IllnessStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialState != oldWidget.initialState) {
      _currentState = widget.initialState;
    }
  }

  Future<void> _applyIllness(String type, double baseDays) async {
    setState(() => _isLoading = true);
    final newState = await _rpgService.applyIllness(type, baseDays, widget.willpower);
    if (newState != null) {
      setState(() {
        _currentState = newState;
      });
      widget.onStateChanged();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _recover() async {
    setState(() => _isLoading = true);
    final success = await _rpgService.recoverIllness();
    if (success) {
      setState(() {
        _currentState = IllnessState(
          id: '',
          type: 'healthy',
          baseDays: 0,
          actualDays: 0,
          startTime: 0,
          isActive: false,
        );
      });
      widget.onStateChanged();
    }
    setState(() => _isLoading = false);
  }

  Widget _buildHealthyState() {
    return Column(
      children: [
        const Icon(Icons.health_and_safety, color: Colors.green, size: 48),
        const SizedBox(height: 8),
        const Text(
          "System Status: Healthy",
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () => _applyIllness('mild_illness', 3.0),
              icon: const Icon(Icons.sick),
              label: const Text("Simulate Mild Illness"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
            ElevatedButton.icon(
              onPressed: () => _applyIllness('physical_injury', 14.0),
              icon: const Icon(Icons.accessible),
              label: const Text("Simulate Injury"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildSickState() {
    final bool isInjury = _currentState!.type == 'physical_injury';
    final Color stateColor = isInjury ? Colors.red : Colors.orange;
    final String stateTitle = isInjury ? "Physical Injury Active" : "Mild Illness Active";

    return Column(
      children: [
        Icon(isInjury ? Icons.accessible : Icons.sick, color: stateColor, size: 48),
        const SizedBox(height: 8),
        Text(
          stateTitle,
          style: TextStyle(color: stateColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: stateColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: stateColor.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Base Duration: ${_currentState!.baseDays} days"),
              Text(
                "Actual Duration (WP reduced): ${_currentState!.actualDays.toStringAsFixed(1)} days",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (isInjury) ...[
                const Text("• Physical tasks locked"),
                const Text("• Atrophy protection for Stamina/Strength"),
                const Text("• -50% visual debuff on physical stats"),
              ] else ...[
                const Text("• XP Decay reduced by 50%"),
                const Text("• Atrophy grace days doubled"),
                const Text("• +200% Willpower XP for all tasks"),
              ]
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _recover,
          icon: const Icon(Icons.healing),
          label: const Text("Recover"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Biological Status",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Divider(),
            if (_isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ))
            else if (_currentState == null || !_currentState!.isActive)
              _buildHealthyState()
            else
              _buildSickState(),
          ],
        ),
      ),
    );
  }
}
