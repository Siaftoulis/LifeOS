import 'package:flutter/material.dart';
import '../../../../../core/audio_dsp_service.dart';
import '../../../../../theme/app_skin_manager.dart';
import 'eq_painters.dart';

/// 1:1 Poweramp Audiophile Tone & Reverb Screen matching Screenshot 1.
class PowerampToneReverbView extends StatefulWidget {
  const PowerampToneReverbView({super.key});

  @override
  State<PowerampToneReverbView> createState() => _PowerampToneReverbViewState();
}

class _PowerampToneReverbViewState extends State<PowerampToneReverbView> {
  final _dsp = AudioDspService.instance;

  late bool _reverbEnabled;
  late double _damp;
  late double _filter;
  late double _fade;
  late double _preDelay;
  late double _preDelayMix;
  late double _size;
  late double _mix;
  late String _preset;

  @override
  void initState() {
    super.initState();
    _loadFromDsp();
  }

  void _loadFromDsp() {
    _reverbEnabled = _dsp.reverbEnabled;
    _damp = _dsp.reverbDamp;
    _filter = _dsp.reverbFilter;
    _fade = _dsp.reverbFade;
    _preDelay = _dsp.reverbPreDelay;
    _preDelayMix = _dsp.reverbPreDelayMix;
    _size = _dsp.reverbSize;
    _mix = _dsp.reverbMix;
    _preset = _dsp.reverbPreset;
  }

  void _syncDsp() {
    _dsp.updateSettings(
      reverbEnabled: _reverbEnabled,
      reverbDamp: _damp,
      reverbFilter: _filter,
      reverbFade: _fade,
      reverbPreDelay: _preDelay,
      reverbPreDelayMix: _preDelayMix,
      reverbSize: _size,
      reverbMix: _mix,
      reverbPreset: _preset,
    );
  }

  void _selectPreset(String name) {
    setState(() {
      _preset = name;
      _dsp.applyReverbPreset(name);
      _loadFromDsp();
    });
  }

  void _reset() {
    _selectPreset('Small Room');
  }

  void _showPresetPicker(AppSkin skin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: skin.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.spatial_audio_rounded, color: skin.accent, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Reverb Presets',
                      style: TextStyle(
                        color: skin.fg,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white12),
              ...AudioDspService.kReverbPresets.keys.map((pName) {
                final isSelected = _preset == pName;
                return ListTile(
                  title: Text(
                    pName,
                    style: TextStyle(
                      color: isSelected ? skin.accent : skin.fg,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded, color: skin.accent, size: 20)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _selectPreset(pName);
                  },
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),

          // Row 1: Damp, Filter, Fade
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDial(
                label: 'Damp',
                value: _damp,
                displayValue: _damp.toStringAsFixed(2),
                skin: skin,
                onChanged: (v) {
                  setState(() {
                    _damp = v;
                    _preset = 'Custom';
                  });
                  _syncDsp();
                },
              ),
              _buildDial(
                label: 'Filter',
                value: _filter,
                displayValue: _filter.toStringAsFixed(2),
                skin: skin,
                onChanged: (v) {
                  setState(() {
                    _filter = v;
                    _preset = 'Custom';
                  });
                  _syncDsp();
                },
              ),
              _buildDial(
                label: 'Fade',
                value: _fade,
                displayValue: _fade.toStringAsFixed(2),
                skin: skin,
                onChanged: (v) {
                  setState(() {
                    _fade = v;
                    _preset = 'Custom';
                  });
                  _syncDsp();
                },
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Row 2: Pre-Delay, Pre-Delay Mix, Size
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDial(
                label: 'Pre-Delay',
                value: _preDelay,
                displayValue: _preDelay.toStringAsFixed(2),
                skin: skin,
                onChanged: (v) {
                  setState(() {
                    _preDelay = v;
                    _preset = 'Custom';
                  });
                  _syncDsp();
                },
              ),
              _buildDial(
                label: 'Pre-Delay Mix',
                value: _preDelayMix,
                displayValue: _preDelayMix.toStringAsFixed(2),
                skin: skin,
                onChanged: (v) {
                  setState(() {
                    _preDelayMix = v;
                    _preset = 'Custom';
                  });
                  _syncDsp();
                },
              ),
              _buildDial(
                label: 'Size',
                value: _size,
                displayValue: _size.toStringAsFixed(2),
                skin: skin,
                onChanged: (v) {
                  setState(() {
                    _size = v;
                    _preset = 'Custom';
                  });
                  _syncDsp();
                },
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Controls & Presets Row: [ Reverb ]  [ Small Room ]  [ Save ]  [ Reset ]
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPillButton(
                label: 'Reverb',
                isActive: _reverbEnabled,
                skin: skin,
                onTap: () {
                  setState(() => _reverbEnabled = !_reverbEnabled);
                  _syncDsp();
                },
              ),
              const SizedBox(width: 8),
              _buildPillButton(
                label: _preset,
                isActive: false,
                isDropdown: true,
                skin: skin,
                onTap: () => _showPresetPicker(skin),
              ),
              const SizedBox(width: 8),
              _buildPillButton(
                label: 'Save',
                isActive: false,
                skin: skin,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Saved custom reverb settings'),
                      backgroundColor: skin.bg1,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildPillButton(
                label: 'Reset',
                isActive: false,
                skin: skin,
                onTap: _reset,
              ),
            ],
          ),

          const SizedBox(height: 36),

          // Row 4: Large Offset Mix dial
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Mix',
                      style: TextStyle(
                        color: skin.fg,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _mix.toStringAsFixed(2),
                      style: TextStyle(
                        color: skin.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                _buildDial(
                  label: '',
                  value: _mix,
                  displayValue: '',
                  size: 96,
                  skin: skin,
                  onChanged: (v) {
                    setState(() {
                      _mix = v;
                      _preset = 'Custom';
                    });
                    _syncDsp();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDial({
    required String label,
    required double value,
    required String displayValue,
    required AppSkin skin,
    required ValueChanged<double> onChanged,
    double size = 78,
  }) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        final delta = -details.primaryDelta! / 140.0;
        final next = (value + delta).clamp(0.0, 1.0);
        onChanged((next * 100).round() / 100.0);
      },
      onHorizontalDragUpdate: (details) {
        final delta = details.primaryDelta! / 140.0;
        final next = (value + delta).clamp(0.0, 1.0);
        onChanged((next * 100).round() / 100.0);
      },
      onDoubleTap: () => onChanged(0.50),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: KnobDialPainter(
                fraction: value,
                color: skin.accent,
                backgroundColor: skin.isOled ? const Color(0xFF141414) : skin.bg2,
                showTicks: false,
              ),
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: skin.fg,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ],
          if (displayValue.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              displayValue,
              style: TextStyle(
                color: skin.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPillButton({
    required String label,
    required bool isActive,
    required AppSkin skin,
    required VoidCallback onTap,
    bool isDropdown = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? skin.accent.withValues(alpha: 0.18) : skin.bg1,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? skin.accent : Colors.white.withValues(alpha: 0.15),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isActive ? skin.accent : skin.fg,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isDropdown) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 16,
                  color: skin.textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
