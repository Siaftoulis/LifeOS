import 'package:flutter/material.dart';
import 'theme/everforest_colors.dart';
import 'app_initializer.dart';
import 'app_lifecycle.dart';

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final s = Stopwatch()..start();
    debugPrint('LifeOSInit: _initializeApp started');
    try {
      // ponytail: min 1s keeps the branded launch screen visible even when
      // init finishes faster (phone ~0.6s); max() semantics via Future.wait
      await Future.wait([
        AppInitializer.initialize(s),
        Future.delayed(const Duration(seconds: 1)),
      ]);
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e, stack) {
      debugPrint("LifeOSInit: Bootstrap error: $e\n$stack");
      if (mounted) {
        setState(() {
          _error = "$e\n$stack";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF09090B),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      // ponytail: branded launch screen (Instagram-style) — logo + tagline,
      // solid bg matches the native splash so it reads as one screen
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: EverforestColors.bg0,
          body: Stack(
            children: [
              Center(
                child: Image.asset(
                  'assets/logo.png',
                  width: 80,
                  height: 80,
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 48.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'from',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'LIFE OS',
                        style: TextStyle(
                          color: EverforestColors.fg,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const LifeOSMainApp();
  }
}
