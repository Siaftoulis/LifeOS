import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../api_client.dart';
import '../../../core/telemetry/telemetry_reporter.dart';

class VoiceRecorderDialog extends StatefulWidget {
  const VoiceRecorderDialog({super.key});

  @override
  State<VoiceRecorderDialog> createState() => _VoiceRecorderDialogState();
}

class _VoiceRecorderDialogState extends State<VoiceRecorderDialog> {
  bool _isRecording = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: EverforestColors.bg1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: EverforestColors.bg2),
      ),
      title: const Text('Voice Input', style: TextStyle(color: EverforestColors.fg)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isRecording ? Icons.mic : Icons.mic_none,
            size: 64,
            color: _isRecording ? EverforestColors.red : EverforestColors.green,
          ),
          const SizedBox(height: 16),
          Text(
            _isRecording ? 'Listening for task...' : 'Tap to start recording',
            style: const TextStyle(color: EverforestColors.grey, fontSize: 14),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: EverforestColors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: EverforestColors.green),
          onPressed: () async {
            if (!_isRecording) {
              setState(() => _isRecording = true);
            } else {
              setState(() => _isRecording = false);
              
              // Submit to backend
              try {
                final res = await ApiClient.instance.postDaemon('/api/v1/voice-parse', {
                  'text': 'Simulated voice input text...',
                });
                TelemetryReporter.instance.track('voice', 'parsed', {});
                
                if (mounted) {
                  Navigator.pop(context);
                  if (res is Map && res['title'] != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Task parsed: ${res['title']} (Priority ${res['priority']})')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Voice task submitted!')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to parse voice: $e', style: const TextStyle(color: EverforestColors.red))),
                  );
                }
              }
            }
          },
          child: Text(_isRecording ? 'Stop & Send' : 'Record', style: const TextStyle(color: EverforestColors.bg0)),
        ),
      ],
    );
  }
}
