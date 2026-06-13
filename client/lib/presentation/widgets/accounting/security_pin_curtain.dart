import 'package:flutter/material.dart';

class SecurityPinCurtain extends StatefulWidget {
  final ValueChanged<String> onVerified;
  final VoidCallback onCancel;

  const SecurityPinCurtain({
    Key? key,
    required this.onVerified,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<SecurityPinCurtain> createState() => _SecurityPinCurtainState();
}

class _SecurityPinCurtainState extends State<SecurityPinCurtain> {
  final TextEditingController _pinController = TextEditingController();

  void _submit() {
    // In a real app, hash and check against cached settings PIN.
    widget.onVerified(_pinController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xD92d353b), // bg0 with high opacity for blur effect
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock,
                color: Color(0xFFa7c080), // accent
                size: 64,
              ),
              const SizedBox(height: 24),
              const Text(
                'Enter Security PIN',
                style: TextStyle(
                  color: Color(0xFFd3c6aa), // fg
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFd3c6aa),
                  fontSize: 24,
                  letterSpacing: 8.0,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF343f44), // bg1
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(color: Color(0xFF859289)), // grey
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFa7c080), // accent
                      foregroundColor: const Color(0xFF2d353b), // bg0
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _submit,
                    child: const Text('VERIFY'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}
