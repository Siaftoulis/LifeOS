import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class DeviceGridToggle extends StatefulWidget {
  final String name;
  final String type;
  final bool isOn;

  const DeviceGridToggle({super.key, required this.name, required this.type, required this.isOn});

  @override
  State<DeviceGridToggle> createState() => _DeviceGridToggleState();
}

class _DeviceGridToggleState extends State<DeviceGridToggle> {
  late bool _isOn;

  @override
  void initState() {
    super.initState();
    _isOn = widget.isOn;
  }

  void _toggle() {
    setState(() => _isOn = !_isOn);
    // Send backend request here
  }

  @override
  Widget build(BuildContext context) {
    final color = _isOn ? EverforestColors.green : EverforestColors.grey;
    final icon = widget.type == 'LIGHT' ? Icons.lightbulb : widget.type == 'THERMOSTAT' ? Icons.thermostat : Icons.power;

    return InkWell(
      onTap: _toggle,
      child: Container(
        decoration: BoxDecoration(
          color: EverforestColors.bg1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _isOn ? EverforestColors.green : EverforestColors.bg2),
          boxShadow: _isOn ? [BoxShadow(color: EverforestColors.green.withOpacity(0.2), blurRadius: 8, spreadRadius: 1)] : [],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 32),
            Text(widget.name, style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
            Text(_isOn ? 'ON' : 'OFF', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
