import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import '../api_client.dart';
import '../database/preferences_service.dart';
import 'feature_registry.dart';
import '../main.dart'; // To access devScreenCaptureKey

class DevSimulationService {
  static final List<String> _traceLogs = [];
  static final Map<String, GlobalKey> _moduleKeys = {};

  static GlobalKey getModuleKey(String moduleId) {
    return _moduleKeys.putIfAbsent(moduleId, () => GlobalKey(debugLabel: 'module_$moduleId'));
  }

  static void appendTraceLog(String log) {
    final entry = '${DateTime.now().toIso8601String()}: $log';
    _traceLogs.add(entry);
    debugPrint('[DevSim] $entry');
  }

  static Future<void> mountAllModules(BuildContext context) async {
    appendTraceLog('Action: Mount All Modules triggered');
    rootScaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(content: Text('Mounting all modules into grid...')));
    
    final modules = FeatureRegistry.availableModules.where((id) => id != 'void').toList();
    const int cols = 5;
    final int rows = (modules.length / cols).ceil();
    
    final List<List<String>> newLayout = [];
    int index = 0;
    for (int r = 0; r < rows; r++) {
      final List<String> row = [];
      for (int c = 0; c < cols; c++) {
        if (index < modules.length) {
          row.add(modules[index]);
          index++;
        } else {
          row.add('void');
        }
      }
      newLayout.add(row);
    }

    await PreferencesService.setLayout(newLayout);
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text('All ${modules.length} modules loaded into a ${rows}x${cols} grid layout.'))
    );
  }

  static bool isIncrementalActive = false;
  static Timer? _incrementalTimer;

  static void onUserInteraction() {
    if (!isIncrementalActive) return;
    _incrementalTimer?.cancel();
    _incrementalTimer = Timer(const Duration(milliseconds: 500), () async {
      appendTraceLog('Action: Incremental Capture triggered');
      try {
        final docDir = await getApplicationDocumentsDirectory();
        final targetDir = Directory('${docDir.path}/LifeOS_Screenshots/incremental');
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
        final ts = DateTime.now().millisecondsSinceEpoch;
        final s = await captureCurrentScreen('incremental_$ts.png');
        if (s != null) {
          final file = File('${targetDir.path}/${s['name']}');
          await file.writeAsBytes(s['bytes']);
          appendTraceLog('Saved incremental screenshot to ${file.path}');
        }
      } catch (e) {
        appendTraceLog('Incremental capture failed: $e');
      }
    });
  }

  static Future<void> captureScreenshots(BuildContext context) async {
    appendTraceLog('Action: Capture UI State triggered');
    
    final ValueNotifier<double> progress = ValueNotifier(0.0);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent, // Don't dim the screen so the user can watch!
      builder: (ctx) => Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF09090B).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF27272A)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Scanning UI Layout...', style: TextStyle(color: Color(0xFFD3C6AA), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Intercepting modules...', style: TextStyle(color: Color(0xFFA7C080), fontSize: 12)),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<double>(
                    valueListenable: progress,
                    builder: (ctx, val, _) => LinearProgressIndicator(
                      value: val,
                      backgroundColor: const Color(0xFF27272A),
                      color: const Color(0xFFA7C080),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    List<Map<String, dynamic>> screenshots = [];
    try {
      screenshots = await _runIterationCapture(progress);
    } catch (e) {
      appendTraceLog('Critical error during crawling: $e');
      rootScaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text('Error during crawl: $e')));
    }
    
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // Close dialog
    }
    
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${docDir.path}/LifeOS_Screenshots');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }
      
      for (var s in screenshots) {
        final file = File('${targetDir.path}/${s['name']}');
        await file.writeAsBytes(s['bytes']);
      }
      try {
        rootScaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text('Saved ${screenshots.length} screenshots to ${targetDir.path}. Incremental mode activated.')));
      } catch (_) {}
      isIncrementalActive = true;
    } catch (e) {
      appendTraceLog('Failed to save locally: $e');
      try { rootScaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text('Failed to save screenshots: $e'))); } catch (_) {}
    }
  }

  static Future<void> traceLogs(BuildContext context) async {
    appendTraceLog('Action: Trace Runtime Logs triggered');
    rootScaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(content: Text('Trace logs buffered.')));
  }

  static Future<void> runFullSimulation(BuildContext context) async {
    appendTraceLog('Action: Run Full Automation Suite triggered');
    
    final ValueNotifier<double> progress = ValueNotifier(0.0);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent, // Don't dim the screen so the user can watch!
      builder: (ctx) => Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF09090B).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF27272A)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Running Automation Suite...', style: TextStyle(color: Color(0xFFD3C6AA), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Crawling app state for daemon...', style: TextStyle(color: Color(0xFFA7C080), fontSize: 12)),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<double>(
                    valueListenable: progress,
                    builder: (ctx, val, _) => LinearProgressIndicator(
                      value: val,
                      backgroundColor: const Color(0xFF27272A),
                      color: const Color(0xFFA7C080),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    List<Map<String, dynamic>> screenshots = [];
    try {
      screenshots = await _runIterationCapture(progress);
    } catch (e) {
      appendTraceLog('Critical error during crawling: $e');
      rootScaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text('Error during crawl: $e')));
    }
    
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // Close dialog
    }
    
    try {
      final daemonUrl = await ApiClient.discoverBaseUrl();
      final url = daemonUrl.replaceAll(':8080', ':50051');
      var request = http.MultipartRequest('POST', Uri.parse('$url/api/v1/devsim/report'));
      
      for (var s in screenshots) {
        request.files.add(http.MultipartFile.fromBytes('screenshots', s['bytes'], filename: s['name']));
      }
      
      final logsString = _traceLogs.join('\n');
      request.files.add(http.MultipartFile.fromString('trace_logs', logsString, filename: 'trace_logs.txt'));
      
      var response = await request.send();
      if (response.statusCode == 200) {
        try {
          rootScaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(content: Text('Simulation uploaded successfully!')));
        } catch (_) {}
      } else {
        try {
          rootScaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text('Upload failed: ${response.statusCode}')));
        } catch (_) {}
      }
    } catch (e) {
      appendTraceLog('Daemon offline or upload failed: $e');
      try {
        final docDir = await getApplicationDocumentsDirectory();
        final targetDir = Directory('${docDir.path}/LifeOS_Screenshots/full_sim_fallback');
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
        for (var s in screenshots) {
          final file = File('${targetDir.path}/${s['name']}');
          await file.writeAsBytes(s['bytes']);
        }
        
        // Also save trace logs!
        final logsFile = File('${targetDir.path}/trace_logs.txt');
        await logsFile.writeAsString(_traceLogs.join('\n'));
        try {
          rootScaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text('Daemon offline. Saved ${screenshots.length} screenshots to ${targetDir.path}')));
        } catch (_) {}
      } catch (saveErr) {
        try {
          rootScaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text('Error uploading and failed to save locally.')));
        } catch (_) {}
      }
    }
    isIncrementalActive = true;
    _traceLogs.clear();
  }

  static Future<List<Map<String, dynamic>>> _runIterationCapture(ValueNotifier<double> progress) async {
    final List<Map<String, dynamic>> screenshots = [];
    
    try {
      final layout = PreferencesService.layout.value;
      int totalModules = 0;
      for (final row in layout) {
        totalModules += row.length;
      }
      
      int currentModuleIndex = 0;

      for (int r = 0; r < layout.length; r++) {
        for (int c = 0; c < layout[r].length; c++) {
          final String moduleId = layout[r][c];
          if (moduleId == 'void' || moduleId.isEmpty) {
            currentModuleIndex++;
            continue;
          }

          appendTraceLog('--- Starting crawling for module: $moduleId at [$r, $c] ---');
          
          try {
            // Physically pan to the module
            spatialEngineKey.currentState?.navigateTo(c, r);
            await Future.delayed(const Duration(milliseconds: 400)); // wait for pan animation to complete
            
            progress.value = currentModuleIndex / totalModules;
          
          final moduleKey = getModuleKey(moduleId);
          final moduleContext = moduleKey.currentContext;
          if (moduleContext == null) {
            appendTraceLog('Failed to capture module context for $moduleId');
            continue;
          }
          
          // 1. Capture base screen screenshot
          final rootScreenshot = await captureCurrentScreen('${moduleId}_root.png');
          if (rootScreenshot != null) {
            screenshots.add(rootScreenshot);
          }
          
          // 2. Capture root scrollables if any
          final rootScrollables = findScrollables(moduleContext as Element);
          for (var sc in rootScrollables) {
            await scrollAndCapture(moduleId, 'root', sc, screenshots);
          }
          
          // 3. Scan and click all clickable widgets
          final rootClickables = findClickables(moduleContext);
          appendTraceLog('Found ${rootClickables.length} clickable elements in $moduleId');
          
          final Set<String> clickedLabels = {};
          
          for (int i = 0; i < rootClickables.length; i++) {
            final clickable = rootClickables[i];
            
            try {
              if (!clickable.mounted) continue;
              
              // Find text label to name the screenshot
              final rawText = getWidgetText(clickable);
              final textLabel = rawText != null ? sanitizeName(rawText) : '${clickable.widget.runtimeType}_index_$i';
              
              // Skip blacklisted widgets
              if (rawText != null && isBlacklisted(rawText)) {
                continue;
              }
              
              if (clickedLabels.contains(textLabel)) {
                continue;
              }
              clickedLabels.add(textLabel);
              
              final callback = getClickCallback(clickable.widget);
              if (callback == null) continue;
              
              appendTraceLog('Action: Click $textLabel in $moduleId');
              try {
                callback();
              } catch (e) {
                appendTraceLog('Error triggering callback for $textLabel: $e');
                continue;
              }
              
              await Future.delayed(const Duration(milliseconds: 300)); // Wait for transitions
              
              // Take screenshot
              final clickScreenshot = await captureCurrentScreen('${moduleId}_clicked_$textLabel.png');
              if (clickScreenshot != null) {
                screenshots.add(clickScreenshot);
              }
              
              // Pop or reset
              final popContext = devScreenCaptureKey.currentContext;
              if (popContext != null) {
                try {
                  final rootNav = Navigator.of(popContext, rootNavigator: true);
                  if (rootNav.canPop()) {
                    rootNav.pop();
                    await Future.delayed(const Duration(milliseconds: 200));
                  } else {
                    await resetModule(moduleId);
                  }
                } catch (_) {
                  await resetModule(moduleId);
                }
              } else {
                await resetModule(moduleId);
              }
            } catch (innerE) {
              appendTraceLog('Error processing clickable in $moduleId: $innerE');
              await resetModule(moduleId); // Recover layout
            }
          }
          } catch (moduleE) {
            appendTraceLog('Critical error crawling module $moduleId: $moduleE');
          }
        // Update progress
        currentModuleIndex++;
        progress.value = currentModuleIndex / totalModules;
        } // end loop c
      } // end loop r
    } finally {
      // Return to origin (home)
      spatialEngineKey.currentState?.navigateTo(0, 0);
    }
    progress.value = 1.0;
    return screenshots;
  }

  static Future<Map<String, dynamic>?> captureCurrentScreen(String name) async {
    final context = devScreenCaptureKey.currentContext;
    if (context != null) {
      try {
        RenderRepaintBoundary boundary = context.findRenderObject() as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(pixelRatio: 1.5);
        ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          Uint8List pngBytes = byteData.buffer.asUint8List();
          return {'name': name, 'bytes': pngBytes};
        }
      } catch (e) {
        appendTraceLog('Failed to capture $name: $e');
      }
    }
    return null;
  }

  static Future<void> scrollAndCapture(
    String moduleId,
    String prefix,
    Element scrollableElement,
    List<Map<String, dynamic>> screenshots,
  ) async {
    if (!scrollableElement.mounted) return;
    if (scrollableElement is! StatefulElement) return;
    
    ScrollableState state;
    try {
      final rawState = scrollableElement.state;
      if (rawState is! ScrollableState) return;
      state = rawState;
    } catch (e) {
      return; // Element state was null due to unmounting
    }
    
    final pos = state.position;
    if (pos.maxScrollExtent <= 0) return;

    appendTraceLog('Scrolling $moduleId ($prefix) - maxScrollExtent: ${pos.maxScrollExtent}');
    
    // Scroll to top first
    pos.jumpTo(0);
    await Future.delayed(const Duration(milliseconds: 300));

    double currentScroll = 0;
    int part = 0;
    while (currentScroll <= pos.maxScrollExtent && part < 5) {
      final name = '${moduleId}_${prefix}_scroll_part_$part.png';
      final s = await captureCurrentScreen(name);
      if (s != null) {
        screenshots.add(s);
      }
      
      final nextScroll = currentScroll + pos.viewportDimension * 0.8;
      if (nextScroll > pos.maxScrollExtent && currentScroll < pos.maxScrollExtent) {
        currentScroll = pos.maxScrollExtent;
      } else if (nextScroll <= pos.maxScrollExtent) {
        currentScroll = nextScroll;
      } else {
        break;
      }
      
      pos.jumpTo(currentScroll);
      await Future.delayed(const Duration(milliseconds: 400));
      part++;
    }
    
    // reset scroll to 0
    pos.jumpTo(0);
    await Future.delayed(const Duration(milliseconds: 200));
  }

  static Future<void> resetModule(String moduleId) async {
    // If we're using visual panning, resetting a module involves popping its navigator if possible
    // We cannot easily reset the state of a single module without replacing the layout or hot restarting.
    // As a safe fallback, we do nothing for now. The previous navigator.pop() logic usually handles it.
  }

  static VoidCallback? getClickCallback(Widget widget) {
    if (widget is GestureDetector) return widget.onTap;
    if (widget is InkWell) return widget.onTap;
    if (widget is ListTile) return widget.onTap;
    if (widget is ElevatedButton) return widget.onPressed;
    if (widget is TextButton) return widget.onPressed;
    if (widget is IconButton) return widget.onPressed;
    if (widget is OutlinedButton) return widget.onPressed;
    return null;
  }

  static String? getWidgetText(Element root) {
    String? foundText;
    void visitor(Element element) {
      if (foundText != null) return;
      try {
        if (!element.mounted) return;
        final widget = element.widget;
        if (widget is Text) {
          foundText = widget.data;
          if (foundText == null && widget.textSpan != null) {
            foundText = widget.textSpan!.toPlainText();
          }
          return;
        } else if (widget is RichText) {
          foundText = widget.text.toPlainText();
          return;
        }
        element.visitChildren(visitor);
      } catch (e) {
        // ignore errors from defunct elements
      }
    }
    if (root.mounted) {
      root.visitChildren(visitor);
    }
    return foundText;
  }

  static String sanitizeName(String input) {
    String s = input.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    s = s.replaceAll(RegExp(r'_{2,}'), '_');
    if (s.startsWith('_')) s = s.substring(1);
    if (s.endsWith('_')) s = s.substring(0, s.length - 1);
    if (s.length > 30) s = s.substring(0, 30);
    return s.trim();
  }

  static bool isBlacklisted(String text) {
    final lower = text.toLowerCase();
    final blacklistKeywords = [
      'automation suite',
      'automation',
      'simulation',
      'capture ui',
      'mount all',
      'trace',
      'logout',
      'log out',
      'lock',
      'signout',
      'sign out',
      'disconnect',
      'reboot',
      'shutdown',
      'shut down',
      'remove',
      'clear',
      'cancel',
      'exit',
      'quit',
      'delete',
      'back',
    ];
    
    for (final kw in blacklistKeywords) {
      if (lower.contains(kw)) {
        return true;
      }
    }
    return false;
  }

  static List<Element> findScrollables(Element root) {
    final List<Element> scrollables = [];
    void visitor(Element element) {
      if (element.widget is Scrollable) {
        scrollables.add(element);
      }
      element.visitChildren(visitor);
    }
    root.visitChildren(visitor);
    return scrollables;
  }

  static List<Element> findClickables(Element root) {
    final List<Element> clickables = [];
    void visitor(Element element) {
      final callback = getClickCallback(element.widget);
      if (callback != null) {
        clickables.add(element);
      }
      element.visitChildren(visitor);
    }
    root.visitChildren(visitor);
    return clickables;
  }
}
