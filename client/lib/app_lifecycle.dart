import 'package:flutter/material.dart';
import 'database/preferences_service.dart';
import 'auth_service.dart';
import 'core/p2p_transfer_service.dart';
import 'update_manager.dart';
import 'api_client.dart';
import 'global_keys.dart';
import 'p2p_dialog_handler.dart';
import 'notification_poll_service.dart';
import 'life_os_main_stack.dart';

class LifeOSMainApp extends StatefulWidget {
  const LifeOSMainApp({super.key});

  @override
  State<LifeOSMainApp> createState() => _LifeOSMainAppState();
}

class _LifeOSMainAppState extends State<LifeOSMainApp> {
  bool _isUnlocked = false;
  final _pollService = NotificationPollService();

  @override
  void initState() {
    super.initState();
    _isUnlocked = AuthService.instance.isAuthenticated;
    AuthService.instance.currentUser.addListener(_handleAuthChange);
    _pollService.start();
    P2PTransferService.instance.onReceiveRequest = _handleP2PReceiveRequest;
  }

  @override
  void dispose() {
    AuthService.instance.currentUser.removeListener(_handleAuthChange);
    _pollService.stop();
    P2PTransferService.instance.onReceiveRequest = null;
    super.dispose();
  }

  void _handleP2PReceiveRequest(String senderName, String fileName, int fileSize, dynamic socket) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      P2PTransferService.instance.declineFile(socket);
      return;
    }
    P2PDialogHandler.handleReceiveRequest(context, senderName, fileName, fileSize, socket);
  }

  void _handleAuthChange() {
    final authenticated = AuthService.instance.isAuthenticated;
    if (authenticated != _isUnlocked) {
      setState(() {
        _isUnlocked = authenticated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        PreferencesService.showPerformanceOverlay,
      ]),
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: rootNavigatorKey,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          ),
          title: 'LifeOS',
          theme: ThemeData.dark(),
          showPerformanceOverlay: PreferencesService.showPerformanceOverlay.value,
          home: Builder(builder: (ctx) {
            WidgetsBinding.instance.addPostFrameCallback((_) => UpdateManager.checkForUpdates(ctx, ApiClient.instance));
            return ValueListenableBuilder<List<List<String>>>(
              valueListenable: PreferencesService.layout,
              builder: (context, layout, _) {
                return LifeOSMainStack(
                  isUnlocked: _isUnlocked,
                  layout: layout,
                  onUnlock: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() => _isUnlocked = true);
                  },
                );
              },
            );
          }),
        );
      },
    );
  }
}
