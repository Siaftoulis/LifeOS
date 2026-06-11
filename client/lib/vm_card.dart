import 'dart:async';
import 'package:flutter/material.dart';
import 'api_client.dart';
import 'database/preferences_service.dart';

enum VMState { running, stopped, starting, stopping }

class VMControlCard extends StatefulWidget {
  final String name;
  final VMState initialState;
  final ApiClient apiClient;
  const VMControlCard({super.key, required this.name, required this.initialState, required this.apiClient});
  @override State<VMControlCard> createState() => _VMCState();
}

class _VMCState extends State<VMControlCard> with SingleTickerProviderStateMixin {
  late VMState _s = widget.initialState;
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  Timer? _t;

  void _action(VMState next) async {
    if (_s == VMState.starting || _s == VMState.stopping) return;
    final prev = _s;
    setState(() => _s = next);
    try {
      await widget.apiClient.post('/api/vm/toggle', {'vm_name': widget.name, 'action': next.name}).timeout(const Duration(seconds: 5));
    } catch (e) {
      if (mounted) setState(() => _s = prev);
    }
  }

  @override Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PreferencesService.activeProfileRole,
      builder: (context, _) {
        final isChild = PreferencesService.activeProfileRole.value == 'CHILD';
        final col = isChild ? Colors.grey : (_s == VMState.running ? Colors.greenAccent : _s == VMState.stopped ? Colors.redAccent : _s == VMState.starting ? Colors.orangeAccent : Colors.grey);
        final isAnim = _s == VMState.starting || _s == VMState.stopping;
        
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(widget.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: FadeTransition(
              opacity: isAnim ? _c : const AlwaysStoppedAnimation(1),
              child: Text(
                isChild ? 'LOCKED (CHILD ACCESS)' : _s.name.toUpperCase(),
                style: TextStyle(color: col, fontWeight: FontWeight.w600),
              ),
            ),
            trailing: IgnorePointer(
              ignoring: isAnim || isChild,
              child: GestureDetector(
                onTapDown: (_) => _s == VMState.running ? _t = Timer(const Duration(milliseconds: 1500), () => _action(VMState.stopping)) : null,
                onTapUp: (_) => _t?.cancel(),
                onTapCancel: () => _t?.cancel(),
                onTap: () => _s == VMState.stopped ? _action(VMState.starting) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: col.withOpacity(0.2)),
                  child: Icon(
                    isChild ? Icons.lock : (_s == VMState.running ? Icons.stop : Icons.play_arrow),
                    color: col,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
